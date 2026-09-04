# vacuity fixtures

One purpose-built spec per vacuity vector in `V2-PLAN.md` §5.3, so that
`harness/vacuity.sh` is pinned by execution rather than by belief.
`harness/test-vacuity.sh` runs every row.

Measured 2026-08-06 against the TLC 2026.03.04.183147 nightly, and re-measured unchanged
on 2026-08-07 against tla2tools v1.8.0 (TLC 2026.07.31.184830). Every row below holds on
both builds.

`DeletedAction.tla`, `UnsatFairness.tla` and `LiveFairness.tla` arrived later, on
2026-09-03 with bead `tla-hf39`, and were measured on v1.8.0 only.
`TranscriptFloor.tla` and `ModelledFloor.tla` arrived on 2026-09-04 with bead
`tla-dk7w`, and were measured on v1.8.0 only. `ObserveLattice.tla` and
`ObserveMixedType.tla` arrived on 2026-09-04 with bead `tla-29m4`, and were
measured on v1.8.0 only.

## The vectors are not variants of each other

They have disjoint causes, they are caught by disjoint guards, and they need
different remediation. A single `VACUOUS` verdict that cannot say which one
fired tells a learner nothing they can act on, so each gets its own token.

| fixture | vector | token | rc | what makes it vacuous |
|---|---|---|---|---|
| `EmptyInit.tla` | 1 | `VACUOUS_EMPTY_SPACE` | 3 | `Init` has no solution; 0 states generated |
| `Healthy.tla` + `DanglingInvariant.cfg` | 2 | `VACUOUS_UNCHECKED` | 4 | healthy space, no invariant configured |
| `DeadGuard.tla` | 3 | `VACUOUS_DEAD_ACTION` | 5 | `Overflow`'s guard is never true |
| `DeletedAction.tla` | 3 | `VACUOUS_DEAD_ACTION` | 5 | `Down` is not a disjunct of `Next`, so it has no coverage row |
| `UnsatFairness.tla` | 4 | `VACUOUS_UNSATISFIABLE` | 7 | fairness demands a step `Next` forbids; no behaviour satisfies `Spec` |
| `TranscriptFloor.tla` at `--min-states 24` | 1 | `VACUOUS_EMPTY_SPACE` | 3 | 12 distinct states, below the problem's floor |
| `Healthy.tla` + `Healthy.cfg` | — | `NON_VACUOUS` | 0 | positive control; nothing is wrong |
| `TerminatingPcal.tla` | — | `NON_VACUOUS` | 0 | false-positive control; see below |
| `LiveFairness.tla` | — | `NON_VACUOUS` | 0 | negative control for vector 4; see below |
| `TranscriptFloor.tla` at `--min-states 4` | — | `NON_VACUOUS` | 0 | **the hole**; the placeholder floor waves it through |
| `ModelledFloor.tla` at `--min-states 24` | — | `NON_VACUOUS` | 0 | negative control for the floor; see below |
| `ObserveLattice.tla` + `ObserveLatticeOne.cfg` | 5 | `VACUOUS_FROZEN_OBSERVE` | 8 | one field of `Observe` never changes |
| `ObserveLattice.tla` + `ObserveLatticePair.cfg` | 5 | `VACUOUS_FROZEN_OBSERVE` | 8 | two fields never change |
| `ObserveLattice.tla` + `ObserveLatticeThree.cfg` | 5 | `VACUOUS_FROZEN_OBSERVE` | 8 | **the hole**; three frozen, one live, nothing catches it today |
| `ObserveLattice.tla` + `ObserveLatticeAll.cfg` | 5 | `VACUOUS_FROZEN_OBSERVE` | 8 | the whole record is constant |
| `ObserveMixedType.tla` | 5 | `VACUOUS_FROZEN_OBSERVE` | 8 | `ledger` frozen, next to a field whose type changes |
| `ObserveLattice.tla` + `ObserveLattice.cfg` | — | `NON_VACUOUS` | 0 | negative control for vector 5; every field moves |

The `DeletedAction.tla` and `UnsatFairness.tla` rows are the contract from bead
`tla-hf39`, not a measurement. As this file is written `vacuity.sh` reports
`NON_VACUOUS` at rc=0 on both of them, which is the bug. The six
`ObserveLattice` and `ObserveMixedType` rows are the contract from bead
`tla-29m4` on the same terms: `vacuity.sh` has no `--observe` flag yet, so it
exits 2 `USAGE` on every one of them. `VACUOUS_FROZEN_OBSERVE` and rc=8 are
that bead's pinned choices, not measurements — rc=8 is free of both tables
this component answers to, `vacuity.sh`'s own 0/2/3/4/5/6/7 and TLC's
0/10/11/12/13/124/150/151/255. Everything else in this README is measured.

## What each fixture proves that the others cannot

**`EmptyInit.tla`** is the trap the component exists to close. Bare TLC on it
reports `No error has been found`, `0 states generated`, and **exits 0**.
Deadlock checking does not catch it either — `test-vacuity.sh` asserts both
controls, because the whole point is that the obvious defences are silent.

**`DanglingInvariant.cfg`** is the vector found on 2026-08-06, after the
original plan was written. It carries no module of its own: it is applied to
`Healthy.tla`, because the module is *fine*. A `.cfg` keyword with no operand
is not an error — TLC accepts the bare `INVARIANT` line, checks nothing, and
exits 0.

**`Gate!NonVacuous` passes this fixture**, measured at rc=0. The state space
is perfectly healthy — 5 distinct states — so a `>= N` threshold has nothing
to complain about. It is not the state space that is empty, it is the
checking. `Gate!InvariantConfigured` is what catches it, at rc=10.

The two guards are disjoint in **both** directions: `InvariantConfigured`
exits 0 on `EmptyInit.tla`, whose `.cfg` does name a real invariant. Neither
subsumes the other, so both run on every problem. `test-vacuity.sh` asserts
each miss directly, since a suite that only shows the finished gate passing
cannot show why the second guard had to exist.

**`TerminatingPcal.tla`** is the false-positive control, and the reason the
dead-action predicate is `total == 0` and never `distinct == 0`. PlusCal
emits `Terminating == pc = "Done" /\ UNCHANGED vars` into every terminating
algorithm, and under `-coverage 1` it reports:

```
<Terminating line 70, col 1 to line 70, col 11 of module TerminatingPcal>: 0:1
```

Zero distinct, one total. The action fires and discovers nothing new, because
a stutter step re-finds the state it started in. A probe keyed on `distinct`
therefore flags this healthy submission — and with it essentially every
PlusCal submission in the problem set. Verified by mutation: with the
predicate changed to `distinct == 0`, this fixture comes back
`VACUOUS_DEAD_ACTION`.

The algorithm is the one from `puzzles/T01-the-light-switch`, on which the
behaviour was first measured. It is reproduced here rather than referenced so
that the fixture cannot be broken by editing a puzzle; the translation is
`pcal`-generated and must be regenerated, not hand-edited, if the algorithm
changes.

**`DeadGuard.tla`** keeps the vector-3 detection honest in the other
direction. Both `NonVacuous` and `InvariantConfigured` pass it — the space is
healthy and the invariant is configured — so it is only reachable by the
coverage probe. Its indented sub-counts are what localize the failure:

```
<Overflow line 20, col 1 to line 20, col 8 of module DeadGuard>: 0:0
  line 20, col 13 to line 20, col 25 of module DeadGuard: 5
  line 20, col 30 to line 20, col 41 of module DeadGuard: 0
```

The last sub-expression with a non-zero count is how far evaluation got, which
is what turns the feedback into "your guard `counter > 100` is never true"
instead of "unreachable". Error location is the only feedback form that
measured as working (§3.7), so `test-vacuity.sh` asserts the guard text
appears in the report, not merely that the verdict fired.

**`DeletedAction.tla`** is `DeadGuard.tla`'s matched pair, and the two together
are what show the dead-action predicate's blind spot. `Overflow` is a disjunct
of `Next` carrying a guard that is never true, so it leaves a row reading `0:0`
and `total == 0` matches it. `Down` here isn't a disjunct at all, so TLC never
generates it and there's no row to match:

```
<Init line 30, col 1 to line 30, col 4 of module DeletedAction>: 1:1
<Up line 31, col 1 to line 31, col 2 of module DeletedAction>: 4:4
```

Same observable behaviour, and the probe catches one and not the other.
Deletion evades it, restriction doesn't. Closing that needs the expected action
**names**, since a name is the only thing a missing row leaves behind.

I put the absent case under the same `VACUOUS_DEAD_ACTION` token rather than
giving it a fourth one, because it's the same probe and the same lesson: an
action you wrote never fired. The remediation is where the two shapes have to
differ. "Your guard is never true" is wrong advice for `Down`, which reads
exactly as it does in `Healthy.tla` and has no guard problem at all.

**`UnsatFairness.tla`** is vector 4, and it's the one where every instrument
this component owns says the spec is healthy. `Reset` is dropped from `Next`
while `WF_counter(Reset)` stays in `Spec`, so fairness demands a step the
next-state relation forbids and no behaviour satisfies `Spec`. Every temporal
obligation then holds over nothing.

The invariants keep biting, because TLC checks those over the state graph and
fairness never touches the state graph. So `NonVacuous` sees 5 distinct states
and passes, `InvariantConfigured` sees a real `INVARIANT` and passes, and no
action reads `total == 0`. Bare TLC reports `OK` at rc=0 with a liveness
`PROPERTY` sitting in the `.cfg`. Only the liveness half goes blind.

**`LiveFairness.tla`** is the same module with `Reset` restored to `Next` and
nothing else changed. Both fairness conjuncts are still there, so a probe that
fires on it is firing on the presence of fairness rather than on fairness the
spec can't meet.

The probe is an always-false **temporal** formula, and the pair measures it:

| run | rc | token |
|---|---|---|
| `[]<>(counter # counter)` vs `UnsatFairness` | 0 | `OK` |
| `[]<>(counter # counter)` vs `LiveFairness` | 13 | `LIVENESS_VIOLATION` |
| `[](counter # counter)` vs `UnsatFairness` | 12 | `SAFETY_VIOLATION` |

The third row is why the formula has to be temporal. `[]P` over a state
predicate isn't a weaker probe, it's a different channel. TLC lifts it into an
invariant, prints `Invariant AlwaysBadState is violated by the initial state`,
and refutes it against the state graph that ignores fairness. So it fires on a
spec with no behaviours at all.

`UnsatFairnessProbe.cfg`, `LiveFairnessProbe.cfg` and
`UnsatFairnessStateProbe.cfg` carry those three runs, and `AlwaysBad` and
`AlwaysBadState` live in the fixtures for them. They pin the measurement. They
don't hand `vacuity.sh` an operator: a learner's module won't define one, so
the real probe has to inject its own. TLC has `-inv expr` and no `-prop`
equivalent, so injecting a temporal formula means generating a `.cfg`.

**`TranscriptFloor.tla`** is the fixture for a hole that is not in any single
probe. Custody step 4 measured a 24-state deterministic script that replays the
published satisfying trace and passes all 13 obligations at rc=0
(`authoring/custody/reports/step4-screens.md:125-142`). The witness probes can't
save it — §3.9 obliges every property to ship a satisfying trace, and any trace
rich enough to teach also threads the finite witness set — so every shape-A
problem honouring §3.9 has the hole.

This fixture is that submission in miniature: a linear chain of scripted steps
with exactly one successor per state. It chooses nothing and models nothing, and
every probe `vacuity.sh` owns passes it. Measured:

```
12 states generated, 12 distinct states found, 0 states left on queue.
<Climb line 35, col 1 to line 35, col 5 of module TranscriptFloor>: 6:6
<Coast line 36, col 1 to line 36, col 5 of module TranscriptFloor>: 5:5
```

The space is healthy, the `INVARIANT` is configured, `Spec` admits behaviours,
and both actions fire. Twelve distinct states clears `Gate!NonVacuous` (`>= 4`)
**three times over**, which is the point: nothing about the miss looks marginal.
Only a floor the problem sets for itself can see it, and that is why the floor
cannot be optional.

**`ModelledFloor.tla`** is its matched pair — the same domain actually modelled,
40 distinct states, run against the **same** floor of 24. A floor that flagged
every submission would satisfy the `TranscriptFloor` row on its own, so the
discriminating thing has to be shown to be the submission rather than the
number.

That is the opposite experiment from the two `Healthy.tla` rows in
`test-vacuity.sh`, which run one fixture at two floors (`--min-states 99` caught,
`--min-states 5` passed). Neither direction substitutes for the other: theirs
shows the number moves the verdict, this pair shows the submission does.

**`ObserveLattice.tla`** is the freeze lattice in one module. Four state
variables that all genuinely move, and one `Observe` record whose four fields
are frozen or live **independently**, chosen by four boolean `CONSTANT`s — so
the five `.cfg` rows differ in nothing but how much of the model the
observation passes through. The state space is 16 distinct states on every row,
all four actions fire on every row, and `Spec` is satisfiable on every row.
Nothing about the model ever breaks; only the window onto it does.

The measurement that makes it a fixture, taken on v1.8.0 with the refinement
idiom from `harness/refinement.sh:22-25` — assert as an ordinary `INVARIANT`
that the expression never leaves its initial value, and require TLC to violate
it, so rc=12 reads *it moves* and rc=0 reads *frozen*:

| row | whole-record probe | reads as |
|---|---|---|
| `ObserveLatticeOne.cfg` | rc=12 | "moves" — **miss** |
| `ObserveLatticeThree.cfg` | rc=12 | "moves" — **miss** |
| `ObserveLatticeAll.cfg` | rc=0 | frozen — caught |

A whole-record probe therefore catches exactly one of the sixteen subsets, and
it is the one subset a learner is least likely to write. The same idiom one
altitude down separates the rows correctly: on `ObserveLatticeThree.cfg`,
`FieldProbeShelf` comes back rc=0 (frozen) and `FieldProbeSeason` rc=12 (it
moves). `ObserveLatticeThreeWholeProbe.cfg`, `...FieldProbe.cfg` and
`...LiveFieldProbe.cfg` are those three runs.

**The only obligation in the module is `TypeOK`, and it is stated over the raw
variables on purpose.** In seedlib every lattice row except V43 is caught by
some obligation that happens to notice — `CloseSquaresTheBook` at V38 and V41,
`DefaultIsNeverClean` at V42, `TheReckoningComes` at V44. That makes the
seedlib package a poor instrument for asking what the *probes* can see, because
an obligation firing masks a probe that saw nothing. Here nothing reads
`Observe` at all, so every row is exactly as visible as the probe layer makes
it, and the answer comes out uniform instead of accidental.

**`ObserveMixedType.tla`** is the field next door. Its `phase` field holds `0`,
`1` and `"closed"` across the reachable space, and TLC does not return `FALSE`
when the two sides of a comparison are of different types — it **aborts the
evaluation**. Measured: `ObserveMixedTypeCrossProbe.cfg`, whose invariant
compares `phase` against a number, comes back `SAFETY_EVAL_FAILURE` at rc=76.
The check never happened.

**The hazard is latent rather than absent, and both readings are pinned.** The
same comparison written the way `refinement.sh` writes it —
`ObserveMixedTypeFieldProbe.cfg`, the field against its initial value — answers
*correctly* here, at rc=12. It answers correctly by luck: `phase` leaves `0` for
`1` before it ever reaches `"closed"`, so TLC stops at that violation and never
evaluates the cross-type case. Hand the same probe a spec whose heterogeneous
field holds its initial value longest and it is the rc=76 above. One row without
the other would say the opposite of what it means.

That is a hazard for a per-field probe specifically, and it fails in the
dangerous direction. `ledger` is frozen on this fixture and is the thing the
gate exists to find; it is sitting beside the field most likely to take the
instrument down, and a run that aborts on `phase` reports nothing about
`ledger` at all. A type-safe comparison exists — `ToString` on both sides
returns rc=12 on `phase` and rc=0 on `ledger`, measured — so the fixture states
a requirement rather than an impossibility, and does not pin how it is met.

The heterogeneity lives in `Observe` rather than in a state variable
deliberately. It is the *observation* the probe reads, so that is where the
hazard has to be for the fixture to exercise it, and it keeps `Next` free of
cross-type guards that would only move the same abort earlier.

## Fixtures that are wrong on purpose

`EmptyInit.tla` has an `Init` with no solution, `DanglingInvariant.cfg` has a
keyword with no operand, `DeadGuard.tla` has an action that can never fire,
`DeletedAction.tla` has an action missing from `Next`, and `UnsatFairness.tla`
has a fairness conjunct no behaviour can meet. Repairing any of them silently
deletes a vector.

`TranscriptFloor.tla` belongs here for a different reason: nothing about it is
*wrong*. It is thin, and its thinness is load-bearing. Adding a branch, or
widening the range past 23, deletes the only fixture that shows a submission
passing every probe while modelling nothing. Its state count and
`ModelledFloor.tla`'s straddle the floor of 24 that `test-vacuity.sh` runs them
both at, so the two counts and that number move together or not at all.

`NoSuchModule.tla` is a fixture by its **absence** — `test-vacuity.sh` uses it
to check that a spec which will not run is reported as `PROBE_INCONCLUSIVE`
rather than as vacuous. Creating a file at that path breaks the row.

`ObserveLattice.tla` belongs here in the `TranscriptFloor.tla` sense: nothing
about the *model* is wrong on any row, and that is the load-bearing part. Give
`season`, `shelf`, `owed` or `standing` a reason not to move, or add an
obligation that reads `Observe`, and the module stops being able to ask what
the probe layer can see on its own. The four `Freeze*` constants are the only
thing that varies between rows, and a fifth field or a sixth `.cfg` should
follow that same shape rather than forking the module.

`ObserveMixedType.tla`'s `phase` field is heterogeneous on purpose. Making it
uniformly numeric deletes the only fixture that shows a per-field probe dying
on one field and taking its neighbour's verdict with it.

`Gate.tla` is **not** here and must not be copied here. It is centrally owned
at `harness/Gate.tla`, shared with §5.4, and `vacuity.sh` reaches it through
the `TLA-Library` property rather than through a copy that could drift.
