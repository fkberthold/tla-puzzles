# Answer

```tla
Halted == stage \in {"done", "failed"}

HaltsOnlyFinished == ~Halted => ENABLED Next
```

Declared as an `INVARIANT`. As a property it's the same thing under a box:

```tla
[](~Halted => ENABLED Next)
```

`ENABLED Next` is true in a state from which some `Next` step exists. It's
a state predicate built from an action, and it's the one construct that
lets you say "a step is possible" without copying the guards.

It replaces deadlock checking. TLC's built-in check reports any state with
no successor, and done and failed are such states on purpose. On the fixed
pipeline `CHECK_DEADLOCK TRUE` exits 11. The invariant exits 0 on the same
pipeline and 12 on the buggy one.

The bug the prompt describes: evict during testing with the retry already
spent. The state (testing, no artifact, 1 retry) has no successor.

## Measured

| run | pipeline | form | rc |
|---|---|---|---|
| `AnswerInvBuggyRun` | buggy | invariant | rc 12 |
| `AnswerInvFixedRun` | fixed | invariant | rc 0 |
| `AnswerPropBuggyRun` | buggy | boxed property | rc 12 |
| `AnswerPropFixedRun` | fixed | boxed property | rc 0 |
| `InlinedBuggyRun` | buggy | guard written out by hand | rc 12 |
| `n5-deadlock-fixed` | fixed | `CHECK_DEADLOCK TRUE` | rc 11 |
| `n5-deadlock-buggy` | buggy | `CHECK_DEADLOCK TRUE` | rc 11 |

The buggy runs report 15 distinct states at the violation. The fixed
pipeline has 15 in all.

## Elimination table

This item has no row table, so each neighbor is killed by a run rather
than a row.

| wrong neighbor | run | rc | why |
|---|---|---|---|
| `[]<>Halted` | fixed | 13 | liveness. Without fairness a retry loop is a counterexample on the correct pipeline |
| `<>Halted` | fixed | 13 | the same |
| `[](~Halted => Next)` | buggy | 150 | SANY: "[] followed by action not of form [A]_v." An action isn't a state predicate, and `ENABLED` is the bridge |
| `~Halted => ENABLED Next` as a PROPERTY, no box | buggy | 0 | a state predicate under PROPERTY is checked on initial states only. Under INVARIANT it's checked everywhere |
| `CHECK_DEADLOCK TRUE` | fixed | 11 | can't exempt the two stages that are meant to stop |
| the guard written out by hand | buggy | 12 | right on this pipeline, equal to the answer as a predicate, and wrong the day someone adds a stage |

## Runs

Every module below is a three-line wrapper that extends the pipeline spec
and runs the cfg beside it, which is the pairing `harness/drill-gate.sh`
checks. The two deadlock rows are cfgs with no wrapper, because the verdict
script refuses that keyword without its -d flag and the gate never passes
one. `bash drill/temporal/verify-item.sh drill/temporal/07-pipeline-halt`
reproduces the whole column, deadlock rows included.

| module | spec | rows | checks | rc |
|---|---|---|---|---|
| `AnswerInvBuggyRun` | `Spec` | - | `INVARIANT HaltsOnlyFinished` | rc 12 |
| `AnswerInvFixedRun` | `SpecFixed` | - | `INVARIANT HaltsOnlyFinishedFixed` | rc 0 |
| `AnswerPropBuggyRun` | `Spec` | - | `PROPERTY AnswerProp` | rc 12 |
| `AnswerPropFixedRun` | `SpecFixed` | - | `PROPERTY AnswerPropFixed` | rc 0 |
| `InlinedBuggyRun` | `Spec` | - | `INVARIANT Inlined` | rc 12 |
| `N1FixedRun` | `SpecFixed` | - | `PROPERTY N1` | rc 13 |
| `N2FixedRun` | `SpecFixed` | - | `PROPERTY N2` | rc 13 |
| `N3BuggyRun` | `Spec` | - | `PROPERTY N3` | rc 150 |
| `N4BuggyRun` | `Spec` | - | `PROPERTY N4` | rc 0 |
| `n5-deadlock-buggy` | `Spec` | - | `CHECK_DEADLOCK TRUE` | rc 11 |
| `n5-deadlock-fixed` | `SpecFixed` | - | `CHECK_DEADLOCK TRUE` | rc 11 |

## Why not in prompt

The prompt is five rules and a requirement in English. The reader has to
retrieve `ENABLED`, know it applies to an action, and know the result is a
state predicate that can go under `INVARIANT` or under a box.

The caveat is the biggest in this family. "Without restating any stage's
rules" is a sentence away from naming the construct. And the hand-written
guard is the same predicate on this system, so no run separates it from the
answer. The difference is what breaks when the pipeline changes, which TLC
can't measure. I'd rank this item last of the eight on telegraphing, and
I'd keep it anyway. `ENABLED` is rated low in the inventory with no
reference spec using it, and a drill corpus that skipped it would leave the
construct uncovered.
