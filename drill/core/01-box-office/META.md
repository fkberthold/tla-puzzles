# META: core/01-box-office

- shape: prose prompt with a checkable state count
- time: 10 min
- trap: two conjuncts each fixing the same primed variable, rc 11 against rc 12
- shows TLA+ in the prompt: no

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them, one per bullet.

- Operator definition
- Equality and inequality
- Integers
- Booleans and logical operators
- Bullet-point boolean notation

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
| `verify/BoxOffice.tla` | 0 | 4 |
| `verify/HalvesComplete.tla` | 11 | 1 |
| `verify/HalfAlone.tla` | 75 | 1 |
| `verify/DoubleFare.tla` | 12 | 2 |
| `verify/HiddenDefect.tla` | 11 | 1 |

Each module has a config of the same name. The two one-state configs carry
`CHECK_DEADLOCK TRUE`, which is what makes the gate pass `-d` to
`harness/verdict.sh`. Without it that channel exits 0 on the same single
state.
