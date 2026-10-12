# 07 donor-session

- family: control-state
- shape: prose situation with a six-step procedure, two rules, a four-row behaviour table, and a closing question that invites the helper
- time: 10 minutes
- shows TLA+ in the prompt: no
- two encodings measured: the spec (rc 0, 199 states) and the neighbour without the nurse guard (rc 12)

## Constructs exercised

Named as `drill/INVENTORY.md` field 4 writes them.

| id | construct | where |
|---|---|---|
| K091 | `Trans` helper action for `pc` transitions | the whole item |
| K089 | ProcSet | domain of `pc`, range of the `\A` in `Terminating` |
| K090 | label-as-action encoding | six actions, six transitions |
| K092 | Terminating | the intended end |
| K054 | `pc[...]` (multi-process pc) | guards and updates |
| K036 | `pc` (PlusCal's label-tracking variable) | hand-rolled, and the only variable |
| K019 | Set filter | `At(label)` |
| K014 | Cardinality | both rules and the chair guard |
| K001 | Operator definition | `At`, `Trans` as parameterised operators |
| K038 | `\E` (existential quantifier, "exists") | `Next` |
| K041 | model value | labels |
| K042 | set of model values | `Donors` |

## The lesson in one line

When every action is a guard plus the same two `pc` lines, the two lines are an operator, and TLC will name that operator in the trace instead of yours.
