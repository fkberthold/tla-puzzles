# Answer

```tla
Beat == last' # last

Answer == []<><<Beat>>_last
```

Infinitely often, a step changes the stored number. The angle brackets are
what let an action say "happens" rather than "is permitted". `<<Beat>>_last`
is a Beat step that changes `last`, so stuttering never satisfies it, and
`[]<>` in front says again and again without end.

## Variants that survive this table

| variant | rows | rc | caveat |
|---|---|---|---|
| `[]<><<last' = (last + 1) % 3>>_last` | 1, 4, 5 / 2 / 3 | 0 / 13 / 13 | agrees here because every cycle has a plus-one step. It would reject (0, 2) cycling, which the prompt's missed heartbeats allow. Not refuted, not right |
| `WF_last(BeatE)` with `BeatE == last' \in ({0, 1, 2} \ {last})` | the same | 0 / 13 / 13 | a fairness formula used as a property. It agrees because Beat is enabled in every state, so weak fairness collapses to "happens infinitely often". Wrong register, right extension |

## Measured

The answer on the allowed set, rows 1, 4 and 5, exits 0 (`AnswerAllowedRun`).
On rows 2 and 3 alone it exits 13 (`AnswerR2Run`, `AnswerR3Run`). Every
module and number is in the Runs section below.

## Elimination table

| wrong neighbor | row | rc | why |
|---|---|---|---|
| `<><<Beat>>_last` | none | 255 | TLC refuses it: "Temporal formulas containing actions must be of forms <>[]A or []<>A." |
| `<>(last # 0)`, its state-level stand-in | 2 | 0 | one beat, then silence, and the formula is content |
| `[]<>(last = 0)` | 5 | 13 | picks a value and waits for it. Beats that skip 0 forever are still beats |
| `[]<>(last = 0) /\ []<>(last = 1) /\ []<>(last = 2)` | 4 | 13 | waits for all three. Row 4 never reaches 2 and is a live peer |
| `[][Beat]_last` | 3 | 0 | a box-action formula admits stuttering by construction, so this one is TRUE everywhere. A box can't say "happens" |
| `[]<>Beat` | none | 150 | SANY: "<> followed by action not of form <<A>>_v." |
| `[]<<Beat>>_last` | none | 150 | SANY: "[] followed by action not of form [A]_v." |

The three refusals are the content here. The first one surprised me. TLC's
liveness checker takes an action only under `[]<>` or `<>[]`, so "eventually
one beat" has no checkable spelling as an action formula on this build. The
SANY pair are the two ways to forget the brackets, and SANY names the form
it wanted in each message.

## Runs

Every module below is a three-line wrapper that extends the trace spec and
runs the cfg beside it, which is the pairing `harness/drill-gate.sh` checks.
`bash drill/temporal/verify-item.sh drill/temporal/02-heartbeat` reproduces
the rc column.

| module | spec | rows | checks | rc |
|---|---|---|---|---|
| `AnswerAllowedRun` | `Spec` | 1, 4, 5 | `PROPERTY Answer` | rc 0 |
| `AnswerR2Run` | `Spec` | 2 | `PROPERTY Answer` | rc 13 |
| `AnswerR3Run` | `Spec` | 3 | `PROPERTY Answer` | rc 13 |
| `N1bR2Run` | `Spec` | 2 | `PROPERTY N1b` | rc 0 |
| `N1R2Run` | `Spec` | 2 | `PROPERTY N1` | rc 255 |
| `N2R5Run` | `Spec` | 5 | `PROPERTY N2` | rc 13 |
| `N3R4Run` | `Spec` | 4 | `PROPERTY N3` | rc 13 |
| `N4R3Run` | `Spec` | 3 | `PROPERTY N4` | rc 0 |
| `N5R1Run` | `Spec` | 1 | `PROPERTY N5` | rc 150 |
| `N6R1Run` | `Spec` | 1 | `PROPERTY N6` | rc 150 |
| `V1AllowedRun` | `Spec` | 1, 4, 5 | `PROPERTY V1` | rc 0 |
| `V1R2Run` | `Spec` | 2 | `PROPERTY V1` | rc 13 |
| `V1R3Run` | `Spec` | 3 | `PROPERTY V1` | rc 13 |
| `V2AllowedRun` | `Spec` | 1, 4, 5 | `PROPERTY V2` | rc 0 |
| `V2R2Run` | `Spec` | 2 | `PROPERTY V2` | rc 13 |
| `V2R3Run` | `Spec` | 3 | `PROPERTY V2` | rc 13 |

## Why not in prompt

The prompt is a column of small integers. The reader has to retrieve that
"keeps happening" is an action property, that an action needs angle
brackets and a subscript to say it happened, and that the temporal shape is
always-eventually.

The caveat: row 4 is only "allowed" because the prompt says the monitor can
miss heartbeats. A reader who skipped that sentence will write the
three-value conjunction, and the table will mark them wrong for a reason
the domain had to supply. And nothing in the table separates "the number
changed" from "the number advanced by one", so the first variant above gets
through on this table and shouldn't in general.
