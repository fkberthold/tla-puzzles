# 02 pumps

- family: control-state
- shape: a handbook extract, two rules, a four-row behaviour table with two foreclosing rows, and a closing question about what records the position in the procedure
- time: 10 minutes
- shows TLA+ in the prompt: no
- two encodings measured: yes, switches only (rc 0, 26 states) and a label per pump (rc 0, 63 states), plus the switches-only neighbour with a guard dropped (rc 12)

## Constructs exercised

One per bullet, spelled as `drill/INVENTORY.md` field 4 spells it.

- pc (PlusCal's label-tracking variable)
- nondeterministic action (\E form and disjunction form)
- action (formal definition)
- function literal
- function set
- EXCEPT
- UNCHANGED
- Cardinality
- Set filter
- \A (universal quantifier, "forall")
- CONSTANT
- set of model values

## Where each lands

| what | where |
|---|---|
| the label-tracking variable | the thing deliberately not written, and measured when it is |
| the nondeterministic action | `Next` |
| the actions | four guarded actions per pump |
| function literal and function set | `Init`, and the shape of `inlet` and `motor` |
| EXCEPT and UNCHANGED | every update |
| Cardinality and the set filter | `Running`, the budget guard, and the budget rule |
| the universal quantifier | `NeverDry` |
| the constants | `Pumps`, `Budget` |

## The lesson in one line

When every guard can be stated on the data, a control variable records a fact the data already holds, and it costs labels to the power of processes for the same verdict.
