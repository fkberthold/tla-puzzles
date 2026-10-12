# 07 donor-session

- family: control-state
- shape: prose situation with a six-step procedure, two rules, a four-row behaviour table, and a closing question that invites the helper
- time: 10 minutes
- shows TLA+ in the prompt: no
- two encodings measured: the spec (rc 0, 199 states) and the neighbour without the nurse guard (rc 12)

## Constructs exercised

One per bullet, spelled as `drill/INVENTORY.md` field 4 spells it.

- Trans helper action for pc transitions
- ProcSet
- label-as-action encoding
- Terminating
- pc[...] (multi-process pc)
- pc (PlusCal's label-tracking variable)
- Set filter
- Cardinality
- Operator definition
- \E (existential quantifier, "exists")
- model value
- set of model values

## Where each lands

| what | where |
|---|---|
| the helper | the whole item |
| ProcSet | domain of `pc`, range of the quantifier in `Terminating` |
| label-as-action | six actions, six transitions |
| Terminating | the intended end |
| the label-tracking variable | hand-rolled, and the only variable |
| the set filter and Cardinality | `At(label)`, both rules, the chair guard |
| operator definitions | `At`, `Trans` as parameterised operators |
| the existential | `Next` |
| model values | labels, `Donors` |

## The lesson in one line

When every action is a guard plus the same two `pc` lines, the two lines are an operator, and TLC will name that operator in the trace instead of yours.
