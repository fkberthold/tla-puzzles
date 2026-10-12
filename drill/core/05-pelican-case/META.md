# META: core/05-pelican-case

- shape: behaviour table, the cycle with its dwell times
- time: 10 min
- lesson: a phase successor and a dwell table, a name for the next phase, a Boolean reset on the primed side
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
- Implication
- LET-IN
- CASE

## Constructs from other families, also exercised

- Sets
- BOOLEAN and integer interval as sets
- Invariant (as a TLA+ operator, checked at every state)
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
| `verify/Pelican.tla` | 0 | 34 |
| `verify/SuccMissingArm.tla` | 75 | 26 |

Each module has a config of the same name. The two configs are identical.
