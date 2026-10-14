# META: functions-records/06-depot-cover

- family: functions-records
- shape: prose, one rule, a five-row behaviour table with one foreclosing row, and a checkable count
- time: 10 min
- lesson: a function merge keeps the left value on a shared key, so which operand goes left is the whole design
- shows TLA+ in the prompt: no

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them, one per bullet.

- @@ (function merge)
- DOMAIN
- function literal

## Constructs from other families, also exercised

- Set filter
- \A (universal quantifier, "forall")
- \E (existential quantifier, "exists")
- UNCHANGED
- BOOLEAN and integer interval as sets
- Invariant (as a TLA+ operator, checked at every state)
- EXTENDS (module import)

## Measured on

TLC2 Version 2026.07.31.184830, `-workers 1`, one config per module, through
`bash drill/functions-records/verify-all.sh 06`. The full table is at the end
of `ANSWER.md`.
