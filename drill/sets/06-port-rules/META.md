# META: sets/06-port-rules

- shape: prose prompt, two rules, a switch and a typed range
- time: 10 min
- lesson: an interval is a set, and a set of intervals needs flattening before it's ports
- shows TLA+ in the prompt: no

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them, one per bullet.

- BOOLEAN and integer interval as sets
- Set map
- Set relational and algebraic operators
- Cartesian product
- Cardinality
- Sets

## Constructs from other families, also exercised

- \E (existential quantifier, "exists")
- Sequences
- Integers
- Booleans and logical operators
- CONSTANT
- Invariant (as a TLA+ operator, checked at every state)

## Keywords with no inventory row

Named as the module spells them.

- UNION

## Verify

| file | rc | distinct states |
|---|---|---|
| `verify/PortsAnswer.tla` | 0 | 274 |
| `verify/PortsNoBand.tla` | 12 | 2 |
| `verify/PortsNoMgmtGuard.tla` | 12 | 12 |
| `verify/PortsFlat.tla` | 75 | 3 |
| `verify/PortsFlatMgmt.tla` | 75 | 3 |

Each module has a config of the same name. Reproduce with
`bash drill/sets/verify-item.sh drill/sets/06-port-rules`.
