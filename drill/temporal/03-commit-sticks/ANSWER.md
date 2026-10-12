# Answer

```tla
Committed == status = "committed"

Answer == [](Committed => []Committed)
```

Once committed, committed forever. And yes, a finite prefix refutes it:
rows 4 and 5 are dead at their third state. It's a safety property wearing
two temporal operators, and the second question exists because that's the
thing people get wrong about it.

## Variants

All three say the same thing as an action: no step leaves committed.

```tla
[][(Committed => Committed')]_status
[][(Committed => UNCHANGED status)]_status
[][(status = "committed") => (status' = "committed")]_status
```

The antecedent is parenthesised on purpose. Without the parentheses SANY
reports an error at the subscript, well to the right of the cause.

## Measured

| run | spec | rows | rc |
|---|---|---|---|
| `AnswerAllowedRun` | with `WF_vars(Advance)` | 1, 2, 3 | rc 0 |
| `AnswerR4Run` | with fairness | 4 | rc 13 |
| `AnswerR5Run` | with fairness | 5 | rc 13 |
| `AnswerR4NofairRun` | no fairness | 4 | rc 12 |
| `AnswerR5NofairRun` | no fairness | 5 | rc 12 |
| `V1R4Run` | with fairness | 4 | rc 13 |
| `V1R4NofairRun` | no fairness | 4 | rc 13 |
| the `V2` and `V3` runs | with fairness | 1, 2, 3 / 4 / 5 | rc 0 / rc 13 / rc 13 |

That's one property, two spellings, and three different exit codes
depending on what else is in the spec.

`harness/verdict.sh:81-91` records `[](P => []P)` as exit 12, measured on a
spec with no fairness. The no-fairness rows above agree. With a fairness
conjunct in the SPECIFICATION the same formula on the same row exits 13.
The box-action spelling exits 13 either way, which the verdict table also
predicts (the implied-action channel).

I suspect the mechanism is that a spec carrying a liveness conjunct sends
every temporal property through the liveness checker, which reports 13
whatever the formula's shape. That's inferred, not read from TLC's source.
What's measured is that the 12-versus-13 split on shape holds for specs
without fairness and doesn't for specs with it. The verdict table should
say so, and the trace spec in `verify/` carries both forms so it can be
re-run.

## Elimination table

| wrong neighbour | row | rc | why |
|---|---|---|---|
| `<>Committed` | 2 | 13 | a transaction that stays pending is allowed, and this rejects it |
| `Pending ~> Committed` | 3 | 13 | an abort is a legal outcome |
| `[](status # "aborted")` | 3 | 12 | "always succeeds" is a different claim |
| `Committed => []Committed` | 4 | 0 | no leading box, so it's tested in the first state only, where nothing is committed |
| `[](Committed => []~Pending)` | 5 | 0 | forbids only the return to pending, and lets committed slide to aborted |
| `<>[]Committed` | 2 | 13 | demands an eventual commit |
| `[]<>Committed` | 2 | 13 | the same |
| `[]Committed` | 1 | 12 | nothing starts committed |

## Runs

Every module below is a three-line wrapper that extends the trace spec and
runs the cfg beside it, which is the pairing `harness/drill-gate.sh` checks.
`bash drill/temporal/verify-item.sh drill/temporal/03-commit-sticks`
reproduces the rc column.

| module | spec | rows | checks | rc |
|---|---|---|---|---|
| `AnswerAllowedNofairRun` | `SpecNoFair` | 1, 2, 3 | `PROPERTY Answer` | rc 0 |
| `AnswerAllowedRun` | `Spec` | 1, 2, 3 | `PROPERTY Answer` | rc 0 |
| `AnswerR4NofairRun` | `SpecNoFair` | 4 | `PROPERTY Answer` | rc 12 |
| `AnswerR4Run` | `Spec` | 4 | `PROPERTY Answer` | rc 13 |
| `AnswerR5NofairRun` | `SpecNoFair` | 5 | `PROPERTY Answer` | rc 12 |
| `AnswerR5Run` | `Spec` | 5 | `PROPERTY Answer` | rc 13 |
| `N1R2Run` | `Spec` | 2 | `PROPERTY N1` | rc 13 |
| `N2R3Run` | `Spec` | 3 | `PROPERTY N2` | rc 13 |
| `N3R3Run` | `Spec` | 3 | `PROPERTY N3` | rc 12 |
| `N4R4Run` | `Spec` | 4 | `PROPERTY N4` | rc 0 |
| `N5R5Run` | `Spec` | 5 | `PROPERTY N5` | rc 0 |
| `N6R2Run` | `Spec` | 2 | `PROPERTY N6` | rc 13 |
| `N7R2Run` | `Spec` | 2 | `PROPERTY N7` | rc 13 |
| `N8R1Run` | `Spec` | 1 | `PROPERTY N8` | rc 12 |
| `V1AllowedRun` | `Spec` | 1, 2, 3 | `PROPERTY V1` | rc 0 |
| `V1R4NofairRun` | `SpecNoFair` | 4 | `PROPERTY V1` | rc 13 |
| `V1R4Run` | `Spec` | 4 | `PROPERTY V1` | rc 13 |
| `V1R5Run` | `Spec` | 5 | `PROPERTY V1` | rc 13 |
| `V2AllowedRun` | `Spec` | 1, 2, 3 | `PROPERTY V2` | rc 0 |
| `V2R4Run` | `Spec` | 4 | `PROPERTY V2` | rc 13 |
| `V2R5Run` | `Spec` | 5 | `PROPERTY V2` | rc 13 |
| `V3AllowedRun` | `Spec` | 1, 2, 3 | `PROPERTY V3` | rc 0 |
| `V3R4Run` | `Spec` | 4 | `PROPERTY V3` | rc 13 |
| `V3R5Run` | `Spec` | 5 | `PROPERTY V3` | rc 13 |

## Why not in prompt

Five rows of three words each. The retrieval is the nested box, and the
second question is the retrieval of what the nesting means for TLC.

The caveat: the rows can't separate the answer from its action-formula
spellings, and I don't want them to, since those are right. What the rows
also can't do is tell the reader that the spellings exit through different
channels. That's in this file and nowhere a reader can derive it. And the
common wrong answer to the second question, "no, it has temporal operators,
so it's liveness", is wrong in a way the table doesn't refute. Only the
prefix argument does.
