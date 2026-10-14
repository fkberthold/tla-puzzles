# 08 wrong-label

- family: control-state
- shape: diagnosis from a shown trace, then production of the corrected action, then elimination of one neighbor by its trace
- time: 10 minutes
- shows TLA+ in the prompt: no. It shows a trace, rendered as a table in English.
- two encodings measured: the spec that produced the trace (rc 12, 3-state trace), the corrected spec (rc 0, 15 states), and three neighbor bugs with their traces (all rc 12)

## Constructs exercised

One per bullet, spelled as `drill/INVENTORY.md` field 4 spells it.

- label-as-action encoding
- EXCEPT
- pc[...] (multi-process pc)
- pc (PlusCal's label-tracking variable)
- UNCHANGED
- ' (prime, next-state value)
- Cardinality
- Set filter
- Terminating

## Where each lands

| what | where |
|---|---|
| label-as-action | the bug is an action naming the wrong successor label |
| EXCEPT | the corrected update, against the `Rebuilt` neighbor's function constructor |
| the multi-process form | the trace's two customer columns |
| the label-tracking variable | reading it from a trace, writing one update of it |
| UNCHANGED and the prime | the corrected action leaves the bay alone and advances one entry |
| Cardinality and the set filter | both rules |
| Terminating | in the reference spec, for the intended end |

## The lesson in one line

By hand, every `pc` update names its own successor, and the label a trace never visits is the one an update skipped.
