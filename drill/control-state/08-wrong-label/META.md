# 08 wrong-label

- family: control-state
- shape: diagnosis from a shown trace, then production of the corrected action, then elimination of one neighbour by its trace
- time: 10 minutes
- shows TLA+ in the prompt: no. It shows a trace, rendered as a table in English.
- two encodings measured: the spec that produced the trace (rc 12, 3-state trace), the corrected spec (rc 0, 15 states), and three neighbour bugs with their traces (A rc 12, B rc 12, C rc 12)

## Constructs exercised

Named as `drill/INVENTORY.md` field 4 writes them.

| id | construct | where |
|---|---|---|
| K090 | label-as-action encoding | the bug is an action naming the wrong successor label |
| K087 | EXCEPT | the corrected update, against neighbour B's function constructor |
| K054 | `pc[...]` (multi-process pc) | the trace's two customer columns |
| K036 | `pc` (PlusCal's label-tracking variable) | reading it from a trace, writing one update of it |
| K085 | UNCHANGED | the corrected action leaves the bay alone |
| K079 | `'` (prime, next-state value) | the update |
| K014 | Cardinality | both rules |
| K019 | Set filter | both rules |
| K092 | Terminating | in the reference spec, for the intended end |

## The lesson in one line

By hand, every `pc` update names its own successor, and the label a trace never visits is the one an update skipped.
