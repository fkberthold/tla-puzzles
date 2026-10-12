# META: core/07-prime-capacity

- shape: prose prompt with a checkable state count
- time: 10 min
- lesson: a universal statement over a range in a definition, an existential choice from a range in an action
- shows TLA+ in the prompt: no

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them, one per bullet.

- Operator definition
- Equality and inequality
- Integers
- Booleans and logical operators
- Bullet-point boolean notation
- \A (universal quantifier, "forall")
- \E (existential quantifier, "exists")

## Constructs from other families, also exercised

- BOOLEAN and integer interval as sets
- Invariant (as a TLA+ operator, checked at every state)
- CONSTANT
- ' (prime, next-state value)
- [P]_x (box action formula)
- VARIABLE / VARIABLES
- vars (the all-variables tuple)
- Init / Next / Spec (the pure-TLA+ spec skeleton)
- action (formal definition)
- UNCHANGED
- nondeterministic action (\E form and disjunction form)

## Verify

| file | rc | distinct states |
|---|---|---|
| `verify/HashTable.tla` | 0 | 85 |
| `verify/GrowAnywhere.tla` | 12 | 5 |

Each module has a config of the same name. The two configs are identical.
