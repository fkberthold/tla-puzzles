# Answer

```tla
Queued  == job = "queued"
Printed == job = "printed"

Answer == Queued ~> Printed
```

Every queued job is eventually printed. The arrow is the only operator in
the answer, and it's the one the table was built to make you retrieve.

## Variants that are the same formula

```tla
[](Queued => <>Printed)
```

That's the definition of leads-to written out. TLC checks the two the same
way, and both were measured on every row below.

## Measured

The answer on the allowed set, rows 1, 2 and 5, exits 0 (`AnswerAllowedRun`).
On each forbidden row alone it exits 13 (`AnswerR3Run`, `AnswerR4Run`,
`AnswerR6Run`). The spelled-out form matches on all four, in the `Answerbox`
runs. Every module and number is in the Runs section below.

A violated leads-to exits 13, the liveness channel, since no finite prefix
refutes it. Row 3 is "queued, then queued forever", and the counterexample
TLC prints ends in a stuttering step.

## Elimination table

Each neighbour is a plausible wrong answer. The row named is the one that
kills it, and the rc is what TLC returned on that row alone.

| wrong neighbour | row | rc | why that row |
|---|---|---|---|
| `<>Printed` | 4 | 0 | one print satisfies it forever, and the second job starves unseen |
| `[]<>Printed` | 2 | 13 | a printer that never gets a job is fine, and this rejects it |
| `<>[]Printed` | 5 | 13 | the tray gets emptied after printing, which is normal |
| `Queued => <>Printed` | 3 | 0 | no leading box, so it's tested in the first state only, where the slot is empty |
| `[](Queued => Printed)` | 1 | 12 | demands printing in the same state as queueing |
| `[][Queued => Printed']_job` | 3 | 0 | a queued job's next change must be to printed, and a job that never changes passes |
| `Printed ~> Queued` | 3 | 0 | arrow the wrong way, and nothing was printed |
| `[]<>(Queued => Printed)` | 6 | 0 | satisfied whenever the slot is empty infinitely often, which row 6 does while starving every job |

Two of those taught me something while I measured them.

`[](Queued => Printed)` exits 12, not 13. It's a safety property written
with a temporal operator, so TLC refutes it with a prefix and reports
through the safety channel. `harness/verdict.sh:81-91` has the table.

`[][Queued => Printed']_job` survives row 1, which I'd expected to kill it.
The queued-to-queued step leaves `job` unchanged, so under the `_job`
subscript it's a stuttering step and the box admits it. Row 3 kills it
instead. That's the subscript doing its job on a formula that was wrong for
a different reason.

## Runs

Every module below is a three-line wrapper that extends the trace spec and
runs the cfg beside it, which is the pairing `harness/drill-gate.sh` checks.
`bash drill/temporal/verify-item.sh drill/temporal/01-print-job` reproduces
the rc column.

| module | spec | rows | checks | rc |
|---|---|---|---|---|
| `AnswerAllowedRun` | `Spec` | 1, 2, 5 | `PROPERTY Answer` | rc 0 |
| `AnswerboxAllowedRun` | `Spec` | 1, 2, 5 | `PROPERTY AnswerBox` | rc 0 |
| `AnswerboxR3Run` | `Spec` | 3 | `PROPERTY AnswerBox` | rc 13 |
| `AnswerboxR4Run` | `Spec` | 4 | `PROPERTY AnswerBox` | rc 13 |
| `AnswerboxR6Run` | `Spec` | 6 | `PROPERTY AnswerBox` | rc 13 |
| `AnswerR3Run` | `Spec` | 3 | `PROPERTY Answer` | rc 13 |
| `AnswerR4Run` | `Spec` | 4 | `PROPERTY Answer` | rc 13 |
| `AnswerR6Run` | `Spec` | 6 | `PROPERTY Answer` | rc 13 |
| `N1R4Run` | `Spec` | 4 | `PROPERTY N1` | rc 0 |
| `N2R2Run` | `Spec` | 2 | `PROPERTY N2` | rc 13 |
| `N3R5Run` | `Spec` | 5 | `PROPERTY N3` | rc 13 |
| `N4R3Run` | `Spec` | 3 | `PROPERTY N4` | rc 0 |
| `N5R1Run` | `Spec` | 1 | `PROPERTY N5` | rc 12 |
| `N6R3Run` | `Spec` | 3 | `PROPERTY N6` | rc 0 |
| `N7R3Run` | `Spec` | 3 | `PROPERTY N7` | rc 0 |
| `N8R6Run` | `Spec` | 6 | `PROPERTY N8` | rc 0 |

## Why not in prompt

The prompt gives six behaviours and no operator. The rows pin the property
by what it admits, and retrieving the arrow as the name of that extension
is the whole exercise. Any code in the prompt would carry the shape of the
answer.

The honest caveat: six rows can't separate the answer from any formula that
agrees with it on those six. `[](Queued => <>Printed) /\ TRUE` is the silly
case. A property that mentions the empty state in some way the rows never
exercise is the real one. A reader who hands in a longer formula that passes
all six has answered the table, and the review has to say whether it's also
the property in the title. I think that's a fair price for a prompt with no
code in it.
