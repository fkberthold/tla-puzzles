# META: core/06-can-pyramid

- shape: prose prompt with a design requirement (one definition, two rules)
- time: 10 min
- lesson: a recursive total with an operator-valued parameter, called with an anonymous operator
- shows TLA+ in the prompt: no

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them, one per bullet.

- Operator definition
- IF-THEN-ELSE
- Equality and inequality
- Integers
- Strings
- Booleans and logical operators
- Bullet-point boolean notation
- RECURSIVE
- Higher-order operator parameter
- LAMBDA

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
| `verify/CanPyramid.tla` | 0 | 10 |
| `verify/RemoveOffByOne.tla` | 12 | 6 |
| `verify/ClosedForms.tla` | 0 | 10 |

Each module has a config of the same name. The three configs are identical.
