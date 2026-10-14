# META: functions-records/01-shunting-yard

- family: functions-records
- shape: prose prompt with a checkable state count and a closing prediction
- time: 10 min
- lesson: a function set and a function literal, one each in the two lines they belong to, and the four swaps measured
- shows TLA+ in the prompt: no

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them, one per bullet.

- function literal
- function set
- EXCEPT

## Constructs from other families, also exercised

- \A (universal quantifier, "forall")
- \E (existential quantifier, "exists")
- CONSTANT
- set of model values
- Invariant (as a TLA+ operator, checked at every state)
- VARIABLE / VARIABLES
- Init / Next / Spec (the pure-TLA+ spec skeleton)
- action (formal definition)
- nondeterministic action (\E form and disjunction form)

## Measured on

TLC2 Version 2026.07.31.184830, `-workers 1`, one config per module, through
`bash drill/functions-records/verify-all.sh 01`. The full table is at the end
of `ANSWER.md`.
