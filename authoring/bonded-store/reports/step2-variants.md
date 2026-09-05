# bonded-store step 2, reference verification and the seeded-variant matrix

Written under V2-PLAN §9.5 against `authoring/bonded-store/reference/BondedStore.tla`
and `BondedStore.cfg`. I didn't write the reference. Bead `tla-h2cg.7`.

The 37 modules under `step2-variants/` were generated and on disk before I ran
TLC once. That's the freeze, and it doesn't move again whoever ends up
repairing (§9.5b). Section 1 states the matrix and my predictions. Section 2
records the reference's own gate. Section 3 records what each variant did.
Section 4 carries the findings, and section 5 hands the statement author the
violating halves of its trace pairs.

This is rung 1 of batch 2, shape B in situation S9, gate ch11, load vector
1 2 1 0 0 0. I'm the rung's first gate on that vector, so section 2 closes
with the five checks it needs.

## 1. The frozen matrix

Two families. Family S mutates the system and leaves all four obligations in
the `.cfg` untouched. Family P mutates a property and asks whether the weakened
form still catches a system variant the shipped form catches. Shape B puts the
properties in the learner's hands, so a property that passes while missing a
real break is the failure this rung grades on.

Every variant is the reference's translated text with one stated mutation. The
PlusCal source block is dropped on purpose. TLC reads the translation, and
shipping an algorithm the translation no longer matches would be a second,
unstated mutation. `S00` is the control on that decision: same text, no
mutation, and it has to reproduce the reference's own counts or every row below
is measuring my generator instead of the author's spec.

All 37 `.cfg` files are byte-identical copies of the reference's, so every
variant meets the shipped obligations unchanged.

### Family S, system mutations

| id | name | targets | mutation against the reference text |
|---|---|---|---|
| S00 | control | nothing | none |
| S01 | pay-in-store | 1, ambiguity 3 | extra disjunct: `place[l] = "inStore"` sets `dutyPaid[l]` TRUE, `place` unchanged |
| S02 | release-without-paying | 1, rule 3 | release drops the `dutyPaid'` conjunct for `UNCHANGED dutyPaid` |
| S03 | movedon-pays-duty | 1, rule 4 | movement under bond sets `dutyPaid[l]` TRUE |
| S04 | entry-skips-store | 2 | extra disjunct: `notEntered` to `released`, paying in the same step |
| S05 | entry-to-movedon | 2 | extra disjunct: `notEntered` to `movedOn`, duty unchanged |
| S06 | store-back-to-notentered | 3, rule 5, ambiguity 1 | extra disjunct: `inStore` to `notEntered` |
| S07 | writeoff-untyped | 3, TypeOK, ambiguity 6 | extra disjunct: `inStore` to `"writtenOff"`, `Places` left alone |
| S08 | writeoff-typed | 3, ambiguity 6 | the same disjunct, with `"writtenOff"` added to `Places` |
| S09 | reentry | 4, ambiguity 5 | extra disjunct: `movedOn` to `inStore` |
| S10 | released-refund | 4 duty clause, 1 | extra disjunct: `released` sets `dutyPaid[l]` FALSE, `place` unchanged |
| S11 | released-to-movedon | 4 | extra disjunct: `released` to `movedOn`, duty going FALSE in the same step |
| S12 | released-to-movedon-paid | 4, 1 | the same step, duty left TRUE |
| S13 | movedon-to-released | 4 | extra disjunct: `movedOn` to `released`, paying |
| S14 | init-released-then-moves | 4, shortest trace | `Init` opens every lot released and paid, plus S11's disjunct |
| S15 | init-in-store | rule 1 opening | `Init`: `place \in [Lots -> {"notEntered", "inStore"}]` |
| S16 | init-released | rule 1 opening | `Init`: `place \in [Lots -> {"notEntered", "released"}]`, duty tied to place |
| S17 | init-duty-on-notentered | 1, initial state | `Init`: `dutyPaid = [l \in Lots \|-> TRUE]` |
| S18 | init-bad-place | TypeOK, rule 1 | `Init`: every lot opens `"warehoused"` |
| S19 | entry-guard-dropped | rule 2 | entry drops its `await` |
| S20 | release-guard-dropped | rule 3, 2 | release drops its `await` |
| S21 | movedon-guard-dropped | rule 4, 2 | movement under bond drops its `await` |
| S22 | no-entry-action | rule 2, vacuity | the entry disjunct is deleted from `Next` |
| S23 | place-partial | rule 1, TypeOK | `Init`: `place = [l \in {} \|-> "notEntered"]` |
| S24 | duty-derived | ALTERNATIVES.md | `dutyPaid` stops being a variable and becomes `place[l] = "released"` |
| S25 | no-movedon-action | rule 4 | the movement-under-bond disjunct is deleted from `Next` |
| S26 | entry-drags-neighbour | rule 1 atomicity | extra disjunct entering two not-entered lots in one step |

### Family P, property mutations

| id | mutation | run against |
|---|---|---|
| P01 | `MovementIsLawful` subscripted `_(Observe.dutyPaid)` | reference, then S06 |
| P02 | `LeavingIsFinal` subscripted `_(Observe.dutyPaid)` | reference, then S09 |
| P03 | `MovementIsLawful` with the two-ways-out arm dropped | reference, then S06 |
| P04 | `LeavingIsFinal` with the `dutyPaid` clause dropped | reference, then S10 |
| P05 | `DutyMatchesPlace` weakened to `released => paid` | reference, then S01 |

P01 and P02 are the wrong-subscript probes §9.5 asks for. A step that changes
only `place` leaves `Observe.dutyPaid` alone, so `[][A]_(Observe.dutyPaid)` is
satisfied by its own stuttering disjunct and never looks at the action it was
written for. S06 and S09 are both place-only steps, so both should walk past a
learner who subscripts on the wrong field.

P05 measures the claim DESCRIPTION §3 makes about must-be-true 1 holding "in
both directions". S01 pays duty on a stored lot, which the biconditional
catches and a one-way implication can't.

### What I expect back green, and why

Six, and I want them on the record before the runs rather than after.

**S15 and S16** should pass. No obligation pins the opening state.
DESCRIPTION §2 says a fifth item doing that was considered and cut, because a
fifth `.cfg` line breaks the rung's property count. So a green here is the cost
of that decision showing up where it was predicted.

**S24** should pass with the reference's own state counts. The mutation changes
the rendering and no behavior. What it also does is make `DutyMatchesPlace` a
tautology, which is ALTERNATIVES.md's stated reason for refusing it.

**S25** should pass. Deleting an action deletes behaviors, and every obligation
here is a safety property or a boxed action. Both are closed under taking a
subset of the behaviors, so no obligation in the set can see an
under-permissive system. §5.3's `--expect-actions` probe is the instrument for
that shape, not a property.

**S26** should pass. Each lot's own transition in the two-lot step is lawful,
and `MovementIsLawful` quantifies over lots one at a time. Nothing in §2 bounds
how many lots move in one step.

**S22** should pass all four obligations at rc=0 and fail `Gate!NonVacuous` at
rc=10, on one distinct state.

I also expect **P01/S06**, **P02/S09**, **P03/S06** and **P05/S01** back green,
each for the reason in its row above. P04/S10 is the one P row I expect caught,
at rc=12 rather than rc=13, and section 4 says what that measures.

### One prediction against the note on the bead

Central's carried note says `LeavingIsFinal` is implied by `DutyMatchesPlace`
and `MovementIsLawful` together, so finding it with no independent arrow would
be a confirmed finding rather than a hole. I think that's wrong, and S11, S13
and S09 are the measurement. `MovementIsLawful`'s two arms are guarded on a
lot's place being `notEntered` or `inStore`, so neither arm says anything at
all about a lot already out. A step from `released` to `movedOn` that drops the
duty in the same motion lands on an unpaid moved-on lot, which
`DutyMatchesPlace` is happy with. If the implication held, S11 would come back
green.

What I do expect to hold is the narrower claim, that `LeavingIsFinal`'s
**second** clause has no independent arrow. Any step changing only a released
lot's duty leaves that lot released and unpaid, and `DutyMatchesPlace` catches
it first. S10 and P04/S10 are that measurement.

### What I didn't seed, and why

Seven of §6's thirteen resolved ambiguities have no seedable break at this
interface, and I'd rather name them than let a reader count rows and wonder.

Ambiguity 2 (the receiving store) and 8 (goods enter by the keeper's act) are
both about who acts. `Observe` shows the store and not the hands in it, so
neither is a property of any model over this interface, which DESCRIPTION §3
already says in as many words. Seeding them needs a second process and a `pc`,
which is a different system rather than a mutation of this one.

Ambiguities 4 (partial lots), 9 (no money) and 10 (lot creation) all widen the
state rather than break a rule. 11 (three overlapping sets) is closed by
`place` being one function, so there's nowhere for an overlap to live. 12 (the
word "warehouse") is a screener finding about `harness/screen.sh:110` and has
no model in it. 13 (capacity) is an under-permissive guard, and S25 already
carries that shape.

### What counts as caught

An invariant catches at rc=12 and an action property at rc=13, per §9.5 step 5
and bead `tla-94n`. rc=124 is `TIMEOUT` and is never read as uncaught. The
verdict comes from the exit code alone. The obligation name comes from the log,
which is where a name is allowed to come from. A variant caught by `TypeOK`
alone is caught for the wrong reason, and section 3 says so where it happens.

## 2. The reference's own gate

Every run goes through `harness/verdict.sh`, so the verdict is the raw exit
code and nothing reads TLC's stdout. `Gate.tla` is found through
`JAVA_TOOL_OPTIONS="-DTLA-Library=$WT/harness"`, with `$WT` the worktree root.

`$WT` below is the worktree root. Both paths go to `verdict.sh` absolute, and
finding 9 says why that isn't optional.

```
harness/verdict.sh -t 300 --config $REF/BondedStore.cfg $REF/BondedStore.tla
    OK                  rc=0     0.50 s
harness/verdict.sh -t 300 --config $REF/BondedStore.cfg $REF/BondedStore.tla -- -inv FALSE
    SAFETY_VIOLATION    rc=12    0.57 s
harness/verdict.sh -t 300 --config $REF/BondedStore.cfg $REF/BondedStore.tla -p Gate!NonVacuous
    OK                  rc=0     0.50 s
```

Check 2 comes back rc=12, so reachable states exist. Check 3 clears
`Gate.tla`'s placeholder threshold of 4 by a factor of 16.

**Check 4, action coverage.** From the same run's `-coverage 1` table, which
`verdict.sh` passes as part of the canonical invocation. The predicate is
`total == 0`, never `distinct == 0`.

| coverage row | distinct : total |
|---|---|
| `Init` | 1 : 1 |
| `Next` (96 14 98 34), entry | 21 : 48 |
| `Next` (99 14 101 57), release | 21 : 48 |
| `Next` (102 14 104 34), movement under bond | 21 : 48 |

No row sits at zero total. All three arms of the keeper's `either` fire. There's
no `Terminating` row, because one PlusCal label carries no `pc` and the
translation generates none.

**Check 5, the vacuity probes.**

```
harness/vacuity.sh --min-states 4 --observe Observe $REF/BondedStore.tla
    NON_VACUOUS         rc=0
```

Five probes, five passes. The state space is non-empty. An `INVARIANT` is
configured. `Spec` admits a behavior. Every action `Next` mentions fired. Every
field of `Observe` takes more than one value across the reachable states.

**Check 6, the counts.** 145 states generated, 64 distinct, and the complete
state graph has depth 7. TLC's own header line reads `1 worker`, so
`verdict.sh` is running the mandatory `-workers 1`. Those counts are what
`author-notes/ALTERNATIVES.md` recorded, to the state.

### The vector check

Rung 1 of batch 2, load vector 1 2 1 0 0 0. Five checks, five passes.

1. **Property count.** Four obligation lines in the cfg, `TypeOK` and
   `DutyMatchesPlace` under `INVARIANTS`, `MovementIsLawful` and
   `LeavingIsFinal` under `PROPERTIES`. §2.5's level 1 band is two to four, so
   this sits at the top of it.
2. **At least one action property.** Two, both `[][A]_Observe`
   (`reference/BondedStore.tla:73` and `:82`). Level 2 on property kind.
3. **No liveness anywhere.** A grep for `WF_`, `SF_`, `<>`, `~>`, `PROPERTY`
   and `FAIRNESS` over the module and the cfg returns one hit, the cfg's
   `INVARIANTS` keyword. `Spec == Init /\ [][Next]_vars` carries no fairness
   conjunct.
4. **One process, no clock.** The algorithm is one unnamed PlusCal process. A
   grep for `^process`, `^fair process`, `pc =` and `pc'` returns 0 lines, so
   the translation carries no program counter and no clock variable. Level 0 on
   step sources.
5. **Under a second, under 1,000 distinct.** 0.50 s wall and 64 distinct
   states. Level 0 on state space, with about an order of magnitude of headroom
   on the count.

## 3. Results

Each variant ran with the same command, changing only the id:

```
harness/verdict.sh -t 300 --config $VAR/<id>.cfg $VAR/<id>.tla
```

All 37 variant configs hash to `a07443027f4be0361063b3d9dc0d2677`, which is
the reference cfg's own md5. Every variant met the shipped obligations
unchanged. Any variant returning rc=0 ran a second time with
`-p Gate!NonVacuous`.

The obligation column is read out of the log, which is where a name is allowed
to come from. The verdict is the exit code alone.

### Family S

| id | token | rc | obligation reported | trace | distinct |
|---|---|---|---|---|---|
| S00 | `OK` | 0 | control, and it matches the reference | none | 64 |
| S01 | `SAFETY_VIOLATION` | 12 | `DutyMatchesPlace` | 3 states | 7 |
| S02 | `SAFETY_VIOLATION` | 12 | `DutyMatchesPlace` | 3 states | 5 |
| S03 | `SAFETY_VIOLATION` | 12 | `DutyMatchesPlace` | 3 states | 6 |
| S04 | `LIVENESS_VIOLATION` | 13 | `MovementIsLawful` | 2 states | 3 |
| S05 | `LIVENESS_VIOLATION` | 13 | `MovementIsLawful` | 2 states | 3 |
| S06 | `LIVENESS_VIOLATION` | 13 | `MovementIsLawful` | 3 states | 6 |
| S07 | `SAFETY_VIOLATION` | 12 | `TypeOK`, see finding 6 | 3 states | 7 |
| S08 | `LIVENESS_VIOLATION` | 13 | `MovementIsLawful` | 3 states | 7 |
| S09 | `LIVENESS_VIOLATION` | 13 | `LeavingIsFinal` | 4 states | 15 |
| S10 | `SAFETY_VIOLATION` | 12 | `DutyMatchesPlace`, see finding 3 | 4 states | 14 |
| S11 | `LIVENESS_VIOLATION` | 13 | `LeavingIsFinal` | 4 states | 13 |
| S12 | `SAFETY_VIOLATION` | 12 | `DutyMatchesPlace` | 4 states | 14 |
| S13 | `LIVENESS_VIOLATION` | 13 | `LeavingIsFinal` | 4 states | 15 |
| S14 | `LIVENESS_VIOLATION` | 13 | `LeavingIsFinal` | 2 states | 2 |
| S15 | `OK` | 0 | none, `Gate!NonVacuous` rc=0 | uncaught | 64 |
| S16 | `OK` | 0 | none, `Gate!NonVacuous` rc=0 | uncaught | 64 |
| S17 | `SAFETY_VIOLATION` | 12 | `DutyMatchesPlace` | initial state | n/a |
| S18 | `SAFETY_VIOLATION` | 12 | `TypeOK` | initial state | n/a |
| S19 | `SAFETY_VIOLATION` | 12 | `DutyMatchesPlace`, see finding 7 | 4 states | 14 |
| S20 | `LIVENESS_VIOLATION` | 13 | `MovementIsLawful` | 2 states | 3 |
| S21 | `LIVENESS_VIOLATION` | 13 | `MovementIsLawful` | 2 states | 3 |
| S22 | `OK` | 0 | none, `Gate!NonVacuous` rc=10 | uncaught | 1 |
| S23 | `SAFETY_VIOLATION` | 12 | `TypeOK` | initial state | n/a |
| S24 | `OK` | 0 | none, `Gate!NonVacuous` rc=0 | uncaught | 64 |
| S25 | `OK` | 0 | none, `Gate!NonVacuous` rc=0 | uncaught | 27 |
| S26 | `OK` | 0 | none, `Gate!NonVacuous` rc=0 | uncaught | 64 |

21 of 26 mutations caught, 20 by an obligation and S22 by the vacuity gate. No
run hit rc=124, so nothing here is a timeout wearing a pass. S00 is the control
and isn't a mutation, so it isn't in either count.

The five that came back rc=0 on every channel are five of the six the frozen
matrix named in advance, and S22 is the sixth, green on the obligations and red
on the gate exactly as predicted. Nothing came back green that I hadn't already
written down.

### Family P

| id | token | rc | obligation reported | the paired system variant alone |
|---|---|---|---|---|
| P01ref | `OK` | 0 | none | n/a |
| P01s06 | `OK` | 0 | none | S06 is rc=13 |
| P02ref | `OK` | 0 | none | n/a |
| P02s09 | `OK` | 0 | none | S09 is rc=13 |
| P03ref | `OK` | 0 | none | n/a |
| P03s06 | `OK` | 0 | none | S06 is rc=13 |
| P04ref | `OK` | 0 | none | n/a |
| P04s10 | `SAFETY_VIOLATION` | 12 | `DutyMatchesPlace` | S10 is rc=12, same obligation |
| P05ref | `OK` | 0 | none | n/a |
| P05s01 | `OK` | 0 | none | S01 is rc=12 |

Four escapes out of five probes, and the fifth behaves the way section 1
predicted. All ten rows match the frozen prediction.

## 4. Findings

**The gate is green.** Five system variants stayed uncaught and every one was
named in advance with a structural cause. No variant came back green that I
hadn't predicted, so there's no hole for a §9.5b repairer to close. §9.5b
shouldn't be dispatched on this rung.

### 1. Every prediction held, which is the result I'd read first

Six predicted greens, six greens. Ten predicted family-P rows, ten matches.
Zero surprises. I want to be careful about what that buys, because a matrix
whose predictions all hold can mean the property set is sound or it can mean I
wrote a matrix that flatters it. The check on the second reading is the spread:
21 of 26 mutations do get caught, across all four obligations, at rc=12 and
rc=13 both. A matrix built to pass would not have that shape.

### 2. The note on the bead is refuted. `LeavingIsFinal` has four arrows

Central's carried note says `LeavingIsFinal` is implied by `DutyMatchesPlace`
and `MovementIsLawful` together. The measurement says otherwise. S09, S11, S13
and S14 are each reported against `LeavingIsFinal` at rc=13, and each one holds
both other obligations throughout.

The mechanism is in the two arms of `MovementIsLawful`
(`reference/BondedStore.tla:73-80`). Both arms guard on a lot's place being
`notEntered` or `inStore`, so neither says anything at all about a lot that has
already left. S11 takes a released lot to `movedOn` and drops the duty in the
same step. The post-state is a moved-on lot with unpaid duty, which
`DutyMatchesPlace` is perfectly happy with. If the implication held, S11 would
have come back green. It came back rc=13 on a 4-state trace.

So item 4 needs its own cfg line. Dropping it would leave S09, S11, S13 and S14
uncaught.

### 3. The narrower claim does hold. Item 4's duty clause has no arrow

`LeavingIsFinal`'s second clause, the one about duty, is the half that
`DutyMatchesPlace` covers. S10 refunds the duty on a released lot and comes
back rc=12 against `DutyMatchesPlace`, not rc=13. S12 does the same one place
over and routes the same way. P04 then drops the clause outright and P04s10 is
still rc=12, at the same 4-state trace.

I think that's structural rather than lucky, and the argument is short. The
clause only bites on a step that changes an out lot's duty. Any such step leaves
that lot either released and unpaid or moved-on and paid, and the biconditional
refuses both. So no variant can exercise the clause alone. Keep it if you want
the step obligation to read completely, which is the reference's apparent
choice. Don't expect the harness to defend it.

Downstream this matters for the statement. Shape B ships one violating trace per
property, and item 4's trace has to break the place half rather than the duty
half, or it violates item 1 too and the learner who wrote only item 1 looks
wrong when they aren't.

### 4. The wrong-subscript hazard reproduces twice, and it's the sharpest result

P01 subscripts `MovementIsLawful` on `Observe.dutyPaid` and P02 does the same to
`LeavingIsFinal`. Both pass the reference at rc=0, which is expected. Both then
pass the system variant their correct form catches.

S06 takes a stored lot back to not-entered and is rc=13 under the shipped
property. P01s06 is rc=0. S09 brings a moved-on lot back into the store and is
rc=13. P02s09 is rc=0. Both mutations move only `place`, so
`[][A]_(Observe.dutyPaid)` is satisfied by its own stuttering disjunct and never
looks at the action it was written for.

Under shape B the learner writes that subscript. DESCRIPTION §2 already tells
the author both action properties are subscripted over the whole of `Observe`
and never over one field, so the guidance exists. This is the measured cost of
ignoring it, and it's a live failure mode for this problem rather than a
hypothetical.

### 5. Item 1's biconditional is load-bearing, and P05 is the proof

DESCRIPTION §3 claims must-be-true 1 constrains rule 3 "in both directions". It
does. P05 weakens `DutyMatchesPlace` to `released => paid`, which still catches
a free release. S01 pays the duty on a lot still in the store, and the shipped
biconditional catches it at rc=12 on a 3-state trace. P05s01 is rc=0.

Nothing else in the set sees S01 either. The step changes only `dutyPaid` and
leaves `place` at `inStore`, so both arms of `MovementIsLawful` are vacuous and
`LeavingIsFinal`'s antecedent is false. The one-way implication doesn't just
weaken the obligation, it removes the only obligation watching that step.

### 6. An untyped third exit routes to `TypeOK`, and a typed one doesn't

S07 and S08 are the same mutation, a write-off exit from the store, differing
only in whether `"writtenOff"` joins `Places`. S07 is rc=12 against `TypeOK`.
S08 is rc=13 against `MovementIsLawful`.

S07 is caught for the wrong reason. The break it seeds is a third way out of
the store, which is item 3's business, and the type invariant gets there first
because it sits earlier in the cfg and fires on the state rather than the step.
So S07 isn't usable as item-3 material. S08 and S06 both are.

### 7. Dropping the entry guard routes to item 1, not to the movement rule

S19 removes entry's `await` so any lot can be put in the store. I expected a
movement property to catch it. It came back rc=12 against `DutyMatchesPlace`, on
a 4-state trace: a lot is entered, released, then put back in the store carrying
its paid duty, which the biconditional refuses. The movement break is there and
something else sees it first.

Worth knowing before a tutor tries to name the rule a learner broke. The
obligation that fires isn't always the one the mistake belongs to.

### 8. The three structural uncatchables, each with a different cause

**S15 and S16, the unpinned opening.** Both let lots start somewhere other than
not-entered, and both are rc=0. No obligation constrains the initial state
beyond what it constrains everywhere. DESCRIPTION §2 says a fifth item pinning
the opening was considered and cut, because a fifth cfg line breaks the rung's
property count. This is that decision's cost, showing up where it was predicted.

Both come back at 64 distinct states, the reference's own count, from 152
generated rather than 145. The added initial states were already reachable, so
the mutation is invisible to the state count as well as to the obligations. No
property change can close this. A repairer would have to add an `Init` predicate
as a fifth cfg line, and that's a rung decision rather than a repair.

**S25, the under-permissive system.** Deleting the movement-under-bond disjunct
gives rc=0 at 27 distinct states. Deleting an action deletes behaviors, and
every obligation here is a safety property or a boxed action. Both are closed
under taking a subset of the behaviors, so nothing in the set can see a system
that does too little.

The instrument for that shape is §5.3's dead-action probe, and it can't see this
one either. Measured:

```
harness/vacuity.sh --min-states 4 --observe Observe --expect-actions Next $VAR/S25.tla
    NON_VACUOUS         rc=0
```

The reason is worth carrying. TLC prints one coverage row per disjunct of
`Next`, and all three rows on this spec are named `Next`, because the disjuncts
come from one PlusCal `either` inside one label. `--expect-actions` matches
names, so it has nothing to miss. §5.3's own note says a deleted action gets no
row and only a name list can find it. That works when the actions have names.
Here they don't, and a one-label PlusCal algorithm is exactly what
DESCRIPTION §5 asks the author for. I'd flag this as a limit on the probe for
every shape-B problem written at the Airlock's altitude, not as a defect in
this reference.

**S26, the step nobody bounded.** Two not-entered lots enter the store in one
step, and it's rc=0 at 64 distinct states from 169 generated. Each lot's own
transition in that step is lawful, and `MovementIsLawful` quantifies over lots
one at a time. Nothing in DESCRIPTION §2 bounds how many lots move in one step.

This one is a gap in the description rather than in the property set. qsl's
problem has "one envelope at a time" as a stated item precisely because a bureau
needs it. This store may not, since a keeper entering two lots at once breaks no
rule anyone stated. Worth a sentence in Rule 1 on the next description pass,
either way, so the silence is a decision rather than an oversight.

### 9. `Gate` resolution needs an absolute module path, and the harness note says otherwise

`harness/test-vacuity.sh:363` says TLC resolves `Gate` "only when the MAIN
module is given by a relative path (then the CWD is searched) or when
TLA-Library is set (then it need not be)". The second clause doesn't reproduce.
Measured on three runs of the same postcondition against the same reference,
with `Gate.tla` on the library path throughout:

| module path | `TLA-Library` | rc |
|---|---|---|
| relative | set | 150 `PARSE_ERROR` |
| absolute | unset | 150 `PARSE_ERROR` |
| absolute | set | 0 |

The failing log reads `Cannot find source file for module Gate imported in
module BondedStore`. So both conditions are needed, not either. `vacuity.sh`
happens to satisfy both, since it resolves the module to `MODULE_ABS` at
`harness/vacuity.sh:391` before calling `verdict.sh`, which is why nothing has
tripped over this before. Anyone driving `verdict.sh` by hand will.

I'd fix the comment rather than the code. The behavior is fine and the note is
what sends a reader down the wrong path.

### 10. The reference contradicts DESCRIPTION §5 on variable naming

DESCRIPTION §5 narrows the author: "The spec's own variables must not carry the
`Observe` field names. `Observe` has to read as a definition over the state, not
as a rename of it." The shipped spec declares `variables place, dutyPaid` and
defines `Observe == [place |-> place, dutyPaid |-> dutyPaid]`
(`reference/BondedStore.tla:6-12`). That's a rename of the state, field for
field.

The author knew. `author-notes/ALTERNATIVES.md` opens with "`Observe` renders as
the identity over them, field for field. The state is the interface", stated as
a virtue rather than as a departure.

I'm not calling the gate red on it, and I'd rather say why than leave it
implied. §9.5's gate is about whether the property set catches the seeded
breaks, and it does. §2.5's representation rubric puts this rung at level 1,
"a complete spec ships, and the learner writes no state", and the variable-name
question only enters the rubric at levels 2 and 3. So the vector stands.

What's at stake is the pedagogy §5 named: at shape B the learner reads the spec
to find the rules, and identical names let them pattern-match off the field
names instead. That's central's call, not mine. If it's to be closed, it's a
rename in the reference plus a re-run of section 2, and it doesn't touch the
frozen matrix.

### 11. S22 is the vacuity gate earning its place

A store whose entry action is gone passes all four obligations at rc=0 on one
distinct state, every one of them vacuously true. `Gate!NonVacuous` returns
rc=10, and `vacuity.sh` returns `VACUOUS_EMPTY_SPACE` at rc=3 with the right
remediation text. It's the only variant here the obligations miss and the gate
catches, which is the argument for running the gate on every grading run rather
than only on the reference.

The threshold used throughout is `Gate.tla`'s placeholder of 4. At 64 distinct
states the reference clears it 16 times over, so a per-problem floor is worth
setting before this ships. §5.3's `tla-dk7w` note says a floor of 4 is what a
hardcoded transcription clears six times over. Not mine to set here.

### 12. S24 confirms `ALTERNATIVES.md` on the derived duty

Deriving `dutyPaid` from `place` gives rc=0 at 145 generated and 64 distinct,
the reference's own numbers to the state. The two renderings are
indistinguishable to every obligation and to the state count.

What changes is that `DutyMatchesPlace` becomes a tautology over its own
definition. The author's argument is that an obligation nothing can break isn't
an obligation, and the concrete cost is S03, which pays duty on a lot moved on
under bond and is caught at rc=12. Under the derived form S03 can't be written
at all. That's the author's own mutant probe, and it reproduces.

## 5. For the statement author

One violating trace per obligation, all at 4 states or under. Satisfying traces
come from the reference, which is green at rc=0.

| obligation | pick | trace | why this one |
|---|---|---|---|
| `TypeOK` | S18 | initial state | a place outside the four, and `TypeOK` is the sole catcher |
| `DutyMatchesPlace` | S02 | 3 states | a release that doesn't pay is the mistake a person makes |
| `MovementIsLawful`, the way in | S04 | 2 states | not-entered straight to released, paying in the same step |
| `MovementIsLawful`, the two ways out | S06 | 3 states | the store's account quietly erased, which is what the rule is for |
| `LeavingIsFinal` | S11 | 4 states | a released lot moved on with its duty dropped |

Four picks over their siblings, each for a reason.

S02 over S17 for item 1. S17 falls at the initial state and reads as a doctored
opening rather than as a keeper's mistake. S02 takes an ordinary run and drops
the payment.

S04 over S05 and S20 for item 2, all three at 2 states. S04 pays the duty in the
same motion, so the trace shows a lot skipping the store while looking otherwise
correct, which is the shape rule 2 exists to forbid.

S06 over S08 for item 3. S08 needs a fifth place invented in `Places`, and a
learner reading the trace has to accept a place the system doesn't have. S06
sends a lot back to not-entered using only the four.

S11 over S14 for item 4, and this is the one I'd argue hardest. S14 is 2 states
against S11's 4, so it's the shorter trace. It gets there by opening with every
lot released, which contradicts Rule 1's "Every lot starts not yet entered". A
violating trace whose first state breaks a different rule teaches the wrong
thing. S11 costs two more states and every state in it is reachable in the
reference.

DESCRIPTION §2 says none of the four items needs more than two states to break.
As a claim about standalone traces that holds, and S14 is the measurement for
item 4 at exactly 2. As a claim about traces reachable from the shipped `Init`
it doesn't, and the table above is what it actually costs. I'd use the reachable
numbers in the statement, since a learner who runs the reference should be able
to find the trace they were shown.
