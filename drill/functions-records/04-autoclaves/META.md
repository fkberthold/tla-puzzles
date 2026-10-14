# META: functions-records/04-autoclaves

- family: functions-records
- shape: prose, two rules, a checkable count, and a closing question about what a one-field update says about the rest
- time: 10 min
- lesson: an update into a record field, and what @ means at each depth of the path
- shows TLA+ in the prompt: no

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them, one per bullet.

- struct literal
- struct set
- function literal
- function set
- EXCEPT
- @ (the original value, inside EXCEPT)

## Constructs from other families, also exercised

- Cardinality
- Set filter
- \A (universal quantifier, "forall")
- \E (existential quantifier, "exists")
- CONSTANT
- set of model values
- Invariant (as a TLA+ operator, checked at every state)
- BOOLEAN and integer interval as sets
- UNCHANGED

## Measured on

TLC2 Version 2026.07.31.184830, `-workers 1`, one config per module, through
`bash drill/functions-records/verify-all.sh 04`. The full table is at the end
of `ANSWER.md`.
