# refinement fixtures

Purpose-built inputs for `harness/refinement.sh` (V2-PLAN.md §5.4, bead
`tla-kl5.7`). `selftest.sh` runs every row and asserts the raw exit status as
well as the verdict token, so a renumbered table breaks the build instead of
quietly relabelling itself.

Measured 2026-08-06 against the TLC 2026.03.04.183147 nightly, and re-measured unchanged
on 2026-08-07 against tla2tools v1.8.0 (TLC 2026.07.31.184830). Every row below holds on
both builds, with three exceptions added later the same day under bead `tla-nesz`:
`safety-conjunct/`, `fragments/smuggled-trailing.cfg` and `fragments/smuggled-block.cfg`
have been measured on v1.8.0 only.

```
harness/fixtures/refinement/selftest.sh
```

## The pair that carries the bead

`correct/Concrete.tla` and `frozen/Concrete.tla` differ in **one line** — the
`WITH` clause — and nothing else. The concrete spec being graded is identical.
So the verdicts below are attributable to the mapping and to nothing else.

| | `PROPERTY Refines` | `INVARIANT Probe` | refinement.sh |
|---|---|---|---|
| `correct/` — mapping moves | rc=0 | rc=12 | `REFINES` (0) |
| `frozen/` — `level <- 0` | **rc=0** | **rc=0** | `FROZEN_MAPPING` (20) |

**A passing probe is a failing refinement check.** The refinement channel
cannot tell these two apart. Only the probe can.

## The fixture matrix

| fixture | verdict | rc | what it pins |
|---|---|---|---|
| `correct/` | `REFINES` | 0 | the positive control: refines, and the mapping moves |
| `frozen/` | `FROZEN_MAPPING` | 20 | the trapdoor: `WITH level <- 0` passes TLC at rc=0 |
| `forged-probe/` | `FROZEN_MAPPING` | 20 | frozen mapping plus a module-authored probe that lies |
| `broken/` | `REFINEMENT_VIOLATED` | 22 | the negative control: sound mapping, wrong concrete spec |
| `safety-conjunct/` | `REFINEMENT_VIOLATED` | 22 | the same verdict reached from rc=12 instead of rc=13 |
| `theorem-only/` | `THEOREM_ONLY` | 23 | §10 — TLC silently ignores `THEOREM` |
| `implicit-with/` | `IMPLICIT_MAPPING` | 25 | §5.4 — omitting `WITH` is silent |
| `wrapped-with/` | `REFINES` | 0 | the false-positive guard: a stated `WITH` may wrap |
| `gate-shadow/` | `GATE_SHADOWED` | 27 | a problem directory shipping its own `Gate.tla` |
| `fragments/symmetry.cfg` | `UNSOUND_REDUCTION` | 24 | §10 — `SYMMETRY` on a temporal check |
| `fragments/view.cfg` | `UNSOUND_REDUCTION` | 24 | §10 — `VIEW` on a temporal check |
| `fragments/directive.cfg` | `FRAGMENT_REFUSED` | 28 | the config fragment carries data, never directives |
| `fragments/smuggled-trailing.cfg` | `FRAGMENT_REFUSED` | 28 | a directive riding at the end of a `CONSTANT` line |
| `fragments/smuggled-block.cfg` | `UNSOUND_REDUCTION` | 24 | `SYMMETRY` behind a `(* ... *)` comment |
| `fragments/ok.cfg` | `REFINES` | 0 | a legal fragment is accepted |
| `fragments/constant.cfg` | `REFINES` | 0 | proves the splice, by reading the generated `.cfg` |

Two more rows need no fixture of their own, only a different invocation of
`correct/`: `--initial '<< 1 >>'` gives `PROBE_MISDECLARED` (26), and
`--abstract Abstract --with 'level <- 0'` gives `FROZEN_MAPPING` (20) against
the very submission that passes at rc=0 under its own mapping — which is what
"we supply the mapping and grade only the concrete spec" looks like in a test.

## The three fixtures that are wrong on purpose

`broken/`, `theorem-only/` and `forged-probe/` contain deliberate defects, and
`gate-shadow/Gate.tla` is deliberately hostile. Repairing any of them silently
deletes a row.

`theorem-only/` is the sharpest: its concrete spec genuinely does not refine,
and with the `THEOREM` in place and no `PROPERTY` in the `.cfg`, TLC reports
`No error has been found` at rc=0. The claim is addressed to a human reader and
to nobody else.

## One refinement failure, two exit codes

`broken/` and `safety-conjunct/` both fail to refine and both come back
`REFINEMENT_VIOLATED` (22), and TLC reaches that through different codes.
`broken/` breaks the implied action, which needs an infinite behaviour, so it
exits 13. `safety-conjunct/` breaks a `[](Hot => []Hot)` conjunct in the
abstract's own `Spec`, which TLC refutes with a finite prefix, so it exits 12.

The codes split on the **shape of the formula**, not on the `.cfg` keyword that
introduced it (bead `tla-94n`, and the table in `verdict.sh`'s header). A
refinement `PROPERTY` inherits whatever shapes the abstract `Spec` carries, so
it inherits the exit code too. Run A used to route 13 alone and `safety-conjunct/`
fell into the catch-all, reporting `SAFETY_VIOLATION` with no refinement in it
(bead `tla-nesz`).

`safety-conjunct/Abstract.tla` lets the level move both ways on purpose. If
`Next` forbade the downward step as well, the concrete spec would break the
implied action too and its 13 would mask the 12 the fixture exists to produce.

Reading 12 as "the refinement failed" is sound only while run A's `.cfg`
declares no `INVARIANT`, which is why the two `fragments/smuggled-*.cfg` rows
matter more than they look. The fragment is the only caller-supplied text that
reaches that `.cfg`.

## A `.cfg` directive is a token, not a line

The guard that keeps directives out of the constants fragment used to match at
the start of a line, and TLC's `.cfg` parser does not read a `.cfg` that way.
Measured on v1.8.0 against a two-state spec with one violated invariant:

| fragment line | TLC | seen by an anchored match? |
|---|---|---|
| `INVARIANT Bad` | rc=12 | yes |
| `CONSTANT Unused = 6 INVARIANT Bad` | rc=12 | **no** |
| `(* c *) INVARIANT Bad` | rc=12 | **no** |
| `\* INVARIANT Bad` | rc=0 | n/a, a comment to TLC too |

So both refusals were defeatable. `smuggled-trailing.cfg` put an `INVARIANT` in
run A's config against `correct/`, whose refinement is fine, and the run came
back rc=12. `smuggled-block.cfg` got a `SYMMETRY` past the soundness refusal,
which is the worse half: a missed `INVARIANT` mislabels a verdict, while a
missed `SYMMETRY` runs an unsound temporal check that still exits 0.

The guard now strips both comment forms and matches keywords as tokens anywhere.
That also refuses a `CONSTANT` whose value contains one of the words, which is a
false refusal of a legal fragment and the right direction to err in.
`constant.cfg` is the row holding the line: it says `INVARIANT` and `PROPERTY`
behind a `\*` and has to keep passing.

## `cfg/` — the guard-versus-probe matrix, run through raw TLC

The four hand-written configs in `cfg/` are applied to `correct/` and `frozen/`
by `verdict.sh` **directly**, bypassing `refinement.sh`, because the point is to
see each check alone. This is the evidence that the two guards catch disjoint
failures.

| cfg | correct mapping | frozen mapping | discriminates? |
|---|---|---|---|
| `no-property.cfg` + `Gate!RefinementConfigured` | rc=10 | rc=10 | **no** |
| `property.cfg` + `Gate!RefinementConfigured` | rc=0 | rc=0 | **no** |
| `probe.cfg` | rc=12 | **rc=0** | **yes** |

The configuration guard fires on a `.cfg` that never declared the `PROPERTY`,
where the probe is not in play at all; the probe fires on a frozen mapping,
where the guard is silent because the `.cfg` really did declare the `PROPERTY`.
Neither substitutes for the other. TLAiBench has only the first row, which is
why a constant mapping scores a pass on the only public benchmark that grades
TLA+ refinement.

`combined.cfg` is the config V2-PLAN.md §5.4 draws — all three lines in one run
— kept because measuring it is what showed the harness must not do that. Against
`correct/` it gives rc=12 having generated **4 states of the 7 reachable**: the
invariant violation stops the run, so the temporal property was never evaluated
over the three states that were never generated. A combined run reports that the
probe fired and nothing else. `refinement.sh` uses two TLC invocations for this
reason.

## Why the probe operator in `cfg/probe.cfg` is not the one `refinement.sh` uses

A `.cfg` accepts only bare identifiers, so a hand-written probe config has to
name an operator the module defines. `refinement.sh` does not: it generates a
wrapper module and its own `HarnessProbe`, because a module-supplied probe is a
forgeable probe.

`forged-probe/` is that forgery. Its mapping is frozen, and its `Probe` watches
the concrete variable instead of the mapped expression, so raw TLC violates it
at rc=12 — mapping moves, PASS. The harness ignores it and reports
`FROZEN_MAPPING`, identically to `frozen/`. The forgery makes no difference.

A blunter forgery would not have worked: `Probe == FALSE` is rejected by TLC
itself with `The invariant of Probe is equal to FALSE` at rc=151. The forgery
has to be state-dependent to get through, and watching the concrete variable is
also a plausible honest misreading of "the mapped expression" — which is the
reason the harness cannot take a module-supplied probe on trust and sort out
intent afterwards.
