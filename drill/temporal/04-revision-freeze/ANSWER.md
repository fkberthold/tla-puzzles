# Answer

```tla
---- MODULE Document ----
EXTENDS Naturals

VARIABLES rev, published

vars == <<rev, published>>

Init == /\ rev = 0
        /\ published = FALSE

Edit == /\ ~published
        /\ rev' = rev + 1
        /\ UNCHANGED published

Publish == /\ ~published
           /\ published' = TRUE
           /\ UNCHANGED rev

Next == Edit \/ Publish

Spec == Init /\ [][Next]_vars
====
```

Fifteen lines, and every one of them is a retrieval: the variable
declaration, the tuple, the initial predicate, two actions with a prime and
an `UNCHANGED` each, the disjunction, and the box-action formula over the
whole tuple.

## Variants

`Publish` without its `~published` guard is fine. S7 is then a Publish step
or a stuttering step, and both are allowed. `rev = 0 /\ ~published` for
`Init` is fine. `published \in BOOLEAN` is not, since I2 pins it.

## Measured

The rows are checked in two halves, because the step rows start mid-history
and no behaviour of `Spec` begins at revision 3.

| run | checks | rows | rc |
|---|---|---|---|
| `InitI1Run` | `Init` as an invariant of the one state | I1 | rc 0 |
| `InitI2Run`, `InitI3Run` | the same | I2, I3 | rc 12, rc 12 |
| `InitAspropI2Run` | `Init` as a PROPERTY | I2 | rc 13 |
| `NextAllowedRun` | `[][Next]_vars` as a property | S1, S2, S7 | rc 0 |
| `NextS3Run` to `NextS6Run` | the same | S3 to S6 | rc 13 each |

The one-state rows exit 12 as an invariant and 13 as a property. A state
predicate named under PROPERTY is checked on initial states through TLC's
implied-init channel, which `harness/verdict.sh` records as 13. The step
rows exit 13 even though a single step refutes them, because a boxed action
goes through the implied-action channel. Same table, same reason.

## Elimination table

| wrong neighbour | row | rc | why |
|---|---|---|---|
| `Edit` without `UNCHANGED published` | S3 | 0 | a step may then change both at once |
| `Edit` without the `~published` guard | S5 | 0 | edits after publishing |
| `rev' > rev` for `rev' = rev + 1` | S6 | 0 | skips a revision |
| `Publish` as `published' = ~published` | S4 | 0 | unpublishes |
| `Next == Edit /\ Publish` | S1 | 13 | unsatisfiable, so only stuttering is admitted and a plain edit is rejected |
| `[][Next]_rev` | S4 | 0 | a step that leaves `rev` alone is stuttering under this subscript, whatever it does to `published` |
| `[][Next]_published` | S6 | 0 | the same, the other way round |
| `Init == published = FALSE` | I3 | 0 | forgets the revision |
| `Init == rev = 0` | I2 | 0 | forgets the flag |

The two subscript rows are the lesson I'd keep if I had to cut the rest. A
box-action formula says nothing about a step that leaves its subscript
unchanged. Leave a variable out of the tuple and the spec admits any change
to it. That's why 96.2% of resolvable sites in the published corpus
subscript the whole tuple, per `.claude/rules/tla-practice.md` section 2.

## Runs

Every module below is a three-line wrapper that extends the step table and
runs the cfg beside it, which is the pairing `harness/drill-gate.sh` checks.
`bash drill/temporal/verify-item.sh drill/temporal/04-revision-freeze`
reproduces the rc column.

| module | spec | rows | checks | rc |
|---|---|---|---|---|
| `ConjS1Run` | `Spec` | 4 | `PROPERTY Conj` | rc 13 |
| `GtS6Run` | `Spec` | 9 | `PROPERTY Gt` | rc 0 |
| `InitAspropI2Run` | `Spec` | 2 | `PROPERTY AnswerInit` | rc 13 |
| `InitI1Run` | `Spec` | 1 | `INVARIANT AnswerInit` | rc 0 |
| `InitI2Run` | `Spec` | 2 | `INVARIANT AnswerInit` | rc 12 |
| `InitI3Run` | `Spec` | 3 | `INVARIANT AnswerInit` | rc 12 |
| `InitnopubI2Run` | `Spec` | 2 | `INVARIANT InitNoPub` | rc 0 |
| `InitnorevI3Run` | `Spec` | 3 | `INVARIANT InitNoRev` | rc 0 |
| `NextAllowedRun` | `Spec` | 4, 5, 10 | `PROPERTY AnswerNext` | rc 0 |
| `NextS3Run` | `Spec` | 6 | `PROPERTY AnswerNext` | rc 13 |
| `NextS4Run` | `Spec` | 7 | `PROPERTY AnswerNext` | rc 13 |
| `NextS5Run` | `Spec` | 8 | `PROPERTY AnswerNext` | rc 13 |
| `NextS6Run` | `Spec` | 9 | `PROPERTY AnswerNext` | rc 13 |
| `NoguardS5Run` | `Spec` | 8 | `PROPERTY NoGuard` | rc 0 |
| `NounchangedS3Run` | `Spec` | 6 | `PROPERTY NoUnchanged` | rc 0 |
| `SubpubS6Run` | `Spec` | 9 | `PROPERTY SubPub` | rc 0 |
| `SubrevS4Run` | `Spec` | 7 | `PROPERTY SubRev` | rc 0 |
| `ToggleS4Run` | `Spec` | 7 | `PROPERTY Toggle` | rc 0 |

## Why not in prompt

The prompt is five rules and ten rows, and the reader writes the whole
module from nothing. That's the deficit this family exists to drill.

The caveat: each action is pinned by one forbidden row, so the table kills
the natural omissions and nothing else. An `Edit` guard of `rev < 10`
passes every row. So does any `Init` that happens to put `rev` at 0. And
S7, the stuttering row, kills nothing at all, since every box-action
formula admits it. I kept it because a reader who writes `[]Next` without
the brackets should have a row to point at when SANY refuses the module.
