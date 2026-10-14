# META: functions-records/05-tool-crib

- family: functions-records
- shape: prose, one rule, a four-row behavior table, a checkable count, and a closing question about the set of tools out
- time: 10 min
- lesson: a partial function whose domain is state, grown by a merge and shrunk by a rebuild, against a total function with a hole value
- three layouts measured: yes, partial function, total function with a hole value, worker to set of tools, all rc 0 at 63
- shows TLA+ in the prompt: no

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them, one per bullet.

- DOMAIN
- :> (singleton function)
- @@ (function merge)
- function literal
- function set
- EXCEPT

## Constructs from other families, also exercised

- Cardinality
- Set filter
- SUBSET (powerset)
- EXTENDS (module import)
- \A (universal quantifier, "forall")
- \E (existential quantifier, "exists")
- CONSTANT
- set of model values
- Invariant (as a TLA+ operator, checked at every state)

## Measured on

TLC2 Version 2026.07.31.184830, `-workers 1`, one config per module, through
`bash drill/functions-records/verify-all.sh 05`. The full table is at the end
of `ANSWER.md`.
