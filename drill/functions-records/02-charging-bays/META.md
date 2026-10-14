# META: functions-records/02-charging-bays

- family: functions-records
- shape: prose, two rules, a four-row behaviour table, a checkable count, and a closing question about which rule came free
- time: 10 min
- lesson: three layouts of the same state reach the same 37 states, and the layout decides which rule you owe
- three encodings measured: yes, bay's side as two functions, bay's side as a function to records, van's side, all rc 0 at 37, plus both sides kept at once, also 37
- shows TLA+ in the prompt: no

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them, one per bullet.

- function literal
- function set
- struct literal
- struct set
- EXCEPT

## Constructs from other families, also exercised

- UNCHANGED
- \A (universal quantifier, "forall")
- \E (existential quantifier, "exists")
- CONSTANT
- set of model values
- model value
- Invariant (as a TLA+ operator, checked at every state)
- nondeterministic action (\E form and disjunction form)

## Measured on

TLC2 Version 2026.07.31.184830, `-workers 1`, one config per module, through
`bash drill/functions-records/verify-all.sh 02`. The full table is at the end
of `ANSWER.md`.
