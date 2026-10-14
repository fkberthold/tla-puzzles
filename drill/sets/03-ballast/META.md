# META: sets/03-ballast

- shape: prose prompt, one rule, a break-it step on the starting condition
- time: 8 min
- lesson: the powerset is a set of sets to draw from, not a subset test
- shows TLA+ in the prompt: no

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them, one per bullet.

- SUBSET (powerset)
- Cardinality
- Set relational and algebraic operators
- Sets

## Constructs from other families, also exercised

- \E (existential quantifier, "exists")
- ASSUME
- CONSTANT
- set of model values
- Invariant (as a TLA+ operator, checked at every state)
- ' (prime, next-state value)

## Verify

| file | rc | distinct states |
|---|---|---|
| `verify/BallastAnswer.tla` | 0 | 50 |
| `verify/BallastAnyStart.tla` | 12 | 1 |
| `verify/BallastNoGuard.tla` | 12 | 51 |
| `verify/BallastOneLevelUp.tla` | 75 | 2 |
| `verify/BallastBinary.tla` | 150 | parse error |
| `verify/BallastSubseteq.tla` | 0 | 50 |

Each module has a config of the same name. Reproduce with
`bash drill/sets/verify-item.sh drill/sets/03-ballast`.
