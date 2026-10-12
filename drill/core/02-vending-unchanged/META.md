# META: core/02-vending-unchanged

- shape: prose prompt with a checkable state count
- time: 10 min
- trap: a variable an action forgets, in its loud and its silent shape
- shows TLA+ in the prompt: no

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them, one per bullet.

- Operator definition
- Equality and inequality
- Integers
- Booleans and logical operators
- Bullet-point boolean notation

## Constructs from other families, also exercised

`UNCHANGED` is the item's subject, in its tuple form. The inventory files it
under temporal, which is why it sits in this list and not the one above.

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
| `verify/Vending.tla` | 0 | 12 |
| `verify/ForgotUnchanged.tla` | 75 | 1 |
| `verify/TypedInPlace.tla` | 12 | 2 |
| `verify/TypedNextSilent.tla` | 0 | 36 |
| `verify/TypedNextCaught.tla` | 12 | 2 |

Each module has a config of the same name. `TypedNextSilent.cfg` names
`TypeOK` alone. The other four name both invariants.
