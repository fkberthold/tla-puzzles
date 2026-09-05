# floor malting step 4, author-only trace map

Never ships to a learner or a blind agent. It maps each pair under
`authoring/floor-malting/statement/traces/` to the frozen reference obligation
it witnesses, with the provenance of both halves. Bead `tla-h2cg.11`, rung 5 of
batch 2, shape A.

The learner-visible artifact set is exactly `statement/PROBLEM.md` and the seven
files under `statement/traces/`. Shape A ships no spec, so there's no learner
copy of the module. Nothing in this file or in `reports/` is reachable from the
shipped set.

## The map

| pair | obligation | violating half | rc | violating trace | satisfying half |
|---|---|---|---|---|---|
| 1 | `Opening` | S01 opening-turned | 13 | initial state | T1, rc=12, 4 states |
| 2 | `CountBelongsToTheFloor` | S04 kiln-keeps-count | 12 | 2 states | T2, rc=12, 2 states |
| 3 | `OnePairOfHands` | S06 floor-swept | 13 | 2 states | T3, rc=12, 4 states |
| 4 | `TurningAddsOne` | S07 double-turn | 13 | 2 states | T4, rc=12, 3 states |
| 5 | `GoodMaltComesFromReady` | S08 unturned-malt | 13 | 2 states | T5, rc=12, 3 states |
| 6 | `OffTheFloorIsFinal` | S10 back-to-the-floor | 13 | 3 states | T6, rc=12, 3 states |
| 7 | `TheFloorGetsCleared` | S12 fairness-dropped | 13 | 6 states, then a stutter | T7, rc=12, 7 states |

`TypeOK` has no pair on purpose. It's the reference author's own typing rather
than a stated rule, and the statement never asks the learner to produce it.
That leaves seven pairs against the cfg's eight lines.

Every variant here is the one `reports/step2-variants.md` section 5 names as
the shortest catch for that obligation. Nothing was substituted.

## Provenance, violating halves

The step 2 variant modules are committed under
`reports/step2-variants/`, so nothing was recreated from the matrix text. Each
of the seven ran through `harness/verdict.sh -t 300` against the frozen
reference `.cfg` unchanged, from a scratch copy inside the worktree:

```
./harness/verdict.sh -t 300 -c <cfg> --log <log> <variant>.tla
```

All seven came back with the rc and the reported obligation section 3's results
table records. S12 came back at 6 real states and then `State 7: Stuttering`,
which is the six the step 2 table settled on after its first pass reported
seven. Finding 13 asked for a re-run before publishing. This is that re-run, and
it agrees with the six.

Traces render over the `Observe` fields only, states only. Action names,
formulas and obligation names are stripped, so the variant action names
(`Sweep`, `Return`) never appear in the shipped files. Stage values render in
the domain's words, on the floor, good malt and a loss, against the statement's
`{"floor", "malt", "loss"}`. The marker renders as `no count`.

## Provenance, satisfying halves

Hand-designed so each mirrors its violating twin, then machine-validated against
the frozen reference. Three of the seven reach their twin's exact end state by a
lawful route (pairs 1, 3 and 4), and the rest replay the same opening move with
the lawful outcome.

The validator is a scratch module `Walk.tla` that extends the reference, adds a
step index, forces the state sequence, and conjoins the reference's `Next` on
every step. Its invariant is `i < Len(Tr)`, so rc=12 means the walk reached the
last index and the whole run is a behavior of the reference. rc=0 means some step
isn't a `Next` step.

Seven of seven came back rc=12. An eighth trace was planted as a control, a
piece going from nothing to two turnings in one step, and it came back rc=0. So
the validator can fail, and the seven passes mean something.

Neither `Walk.tla` nor the scratch copies are committed. They lived under
`scratch/` inside the worktree and were deleted before the footprint check.

## Notes for step 5 and the grader

- Pass `--expect-actions Turn` and nothing else, or pass no list at all. Step 2's
  finding 4 measured that naming `Kiln` and `ThrowOut` refuses S24, a one-exit
  model the description permits outright. The statement doesn't name any action,
  so a grader that demands three is grading a fork the learner was left free on.
- Pair 2's forbidden run leaves `TypeOK` standing. A piece off the floor carrying
  0 is still a natural number, so the shape claim holds and only the count rule
  breaks. That's a clean single-rule trace, and it's why section 5 picked S04
  over S20, whose broken opening lets the invariant beat `Opening` to the arrow.
- Pair 1's arrow is a source location rather than an operator name. TLC splits a
  `PROPERTIES` state predicate into implied inits per conjunct, so `Opening`
  never appears in the log. Step 2's finding 11 has it, and it reproduces here.
  A tutor reading the log for a name won't find one.
- Pair 7's forbidden run breaks the liveness rule and nothing else. Its allowed
  twin ends by taking the last piece off at `UpperMark`, which is a loss, so the
  pair also shows that the rule is about the floor emptying rather than about
  good malt.
- The statement fixes all seven forms, so the pairs carry no kind information the
  statement withheld. Under shape A their job is the second direction of §3.9:
  an over-constrained model passes every check and still can't produce the
  allowed halves.
