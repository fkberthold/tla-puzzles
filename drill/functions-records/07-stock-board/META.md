# META: functions-records/07-stock-board

- family: functions-records
- shape: prose, a sample of the board as a table, one rule, a checkable count, and a closing question about one cell's read and write path
- time: 10 min
- lesson: a function of records and a record of functions are two readings of one table, and the write path mirrors the read path
- three layouts measured: yes, by rows, by columns, flat, all rc 0 at 216
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

- \A (universal quantifier, "forall")
- \E (existential quantifier, "exists")
- CONSTANT
- set of model values
- Invariant (as a TLA+ operator, checked at every state)
- UNCHANGED
- BOOLEAN and integer interval as sets

## Measured on

TLC2 Version 2026.07.31.184830, `-workers 1`, one config per module, through
`bash drill/functions-records/verify-all.sh 07`. The full table is at the end
of `ANSWER.md`.
