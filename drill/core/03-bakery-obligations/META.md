# META: core/03-bakery-obligations

- shape: prose prompt, three numbered requirements, a break-it step
- time: 12 min
- lesson: separate obligations get separate names, measured over five mutants
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
- deadlock (checking)
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
| `verify/Bakery.tla` | 0 | 40 |
| `verify/DouseWithTray.tla` | 12 | 4 |
| `verify/UnloadNoRoom.tla` | 12 | 14 |
| `verify/SellOverpriced.tla` | 12 | 8 |
| `verify/LoadColdOven.tla` | 12 | 3 |
| `verify/SellUnrung.tla` | 12 | 8 |

Each module has a config of the same name carrying the three names.
`Bundled.cfg` and `TwoNames.cfg` are the other two configs the answer
measures against, run by hand.
