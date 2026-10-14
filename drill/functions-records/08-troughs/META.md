# META: functions-records/08-troughs

- family: functions-records
- shape: prose, one rule, and two checkable counts at two model sizes, the second of which is the foreclosure
- time: 10 min
- lesson: a sum over a parameter is a function defined by recursion on its own index, and the hand-written sum passes at the size it was written for
- shows TLA+ in the prompt: no

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them, one per bullet.

- Bracket function definition
- Recursive function definition
- function literal
- function set
- EXCEPT
- @ (the original value, inside EXCEPT)

## Constructs from other families, also exercised

- RECURSIVE
- IF-THEN-ELSE
- CONSTANT
- \E (existential quantifier, "exists")
- UNCHANGED
- BOOLEAN and integer interval as sets
- Invariant (as a TLA+ operator, checked at every state)

## Measured on

TLC2 Version 2026.07.31.184830, `-workers 1`, one config per module, through
`bash drill/functions-records/verify-all.sh 08`. The full table is at the end
of `ANSWER.md`. `TroughsFour` and `TroughsHardcodedThree` are thin wrappers
that extend the module they're named after and carry the other model size.
