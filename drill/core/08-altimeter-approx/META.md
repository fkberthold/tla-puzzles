# META: core/08-altimeter-approx

- shape: prose prompt with a checkable state count
- time: 10 min
- lesson: a user-defined infix operator, an iff as a rule, a range with a negative end
- shows TLA+ in the prompt: no

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them, one per bullet.

- Operator definition
- Equality and inequality
- Integers
- Booleans and logical operators
- Bullet-point boolean notation
- \E (existential quantifier, "exists")
- Custom binary operator

## Constructs from other families, also exercised

- Sets
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
| `verify/Altimeters.tla` | 0 | 49 |
| `verify/StaleLamp.tla` | 12 | 6 |

Each module has a config of the same name. The two configs are identical.
