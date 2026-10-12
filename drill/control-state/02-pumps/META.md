# 02 pumps

- family: control-state
- shape: a handbook extract, two rules, a four-row behaviour table with two foreclosing rows, and a closing question about what records the position in the procedure
- time: 10 minutes
- shows TLA+ in the prompt: no
- two encodings measured: yes, switches only (rc 0, 26 states) and a label per pump (rc 0, 63 states)

## Constructs exercised

Named as `drill/INVENTORY.md` field 4 writes them.

| id | construct | where |
|---|---|---|
| K036 | `pc` (PlusCal's label-tracking variable) | the thing deliberately not written, and measured when it is |
| K086 | nondeterministic action (\E form and disjunction form) | `Next` |
| K084 | action (formal definition) | four guarded actions per pump |
| K047 | function literal | `Init` |
| K050 | function set | the shape of `inlet` and `motor` |
| K087 | EXCEPT | every update |
| K085 | UNCHANGED | every action |
| K014 | Cardinality | the budget guard and rule |
| K019 | Set filter | `Running` |
| K037 | `\A` (universal quantifier, "forall") | `NeverDry` |
| K039 | CONSTANT | `Pumps`, `Budget` |
| K042 | set of model values | `Pumps` |

## The lesson in one line

When every guard can be stated on the data, a control variable records a fact the data already holds, and it costs labels to the power of processes for the same verdict.
