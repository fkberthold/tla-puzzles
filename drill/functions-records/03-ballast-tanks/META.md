# META: functions-records/03-ballast-tanks

- family: functions-records
- shape: prose, a five-row gauge table with two foreclosing rows, and a checkable count
- time: 10 min
- lesson: two cells change in one step through one update with two clauses, and each clause's @ is its own key's old value
- shows TLA+ in the prompt: no

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them, one per bullet.

- EXCEPT
- @ (the original value, inside EXCEPT)
- function literal
- function set

## Constructs from other families, also exercised

- CONSTANT
- model value
- Invariant (as a TLA+ operator, checked at every state)
- \E (existential quantifier, "exists")
- BOOLEAN and integer interval as sets
- nondeterministic action (\E form and disjunction form)

## Measured on

TLC2 Version 2026.07.31.184830, `-workers 1`, one config per module, through
`bash drill/functions-records/verify-all.sh 03`. The full table is at the end
of `ANSWER.md`.
