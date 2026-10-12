# META: core/04-lift-types

- shape: behaviour table with a foreclosing row at floor -2
- time: 10 min
- lesson: the `TypeOK` idiom, `Int` against `Nat`, and the config's missing negative literal
- shows TLA+ in the prompt: no

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them, one per bullet.

- Operator definition
- Equality and inequality
- Integers
- Strings
- Booleans and logical operators
- Bullet-point boolean notation
- Implication

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
| `verify/Lift.tla` | 0 | 18 |
| `verify/FloorInNat.tla` | 12 | 5 |
| `verify/NegativeInConfig.tla` | 255 | 0 |

Each module has a config of the same name.
