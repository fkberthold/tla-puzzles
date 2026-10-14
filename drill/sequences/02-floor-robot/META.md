# META: sequences/02-floor-robot

- shape: prose, a grid walk with a no-revisit rule
- time: 8 to 10 min
- lesson: a pair is a sequence of length two, the position is the last element, and a rule that looks one ahead stops one short
- shows TLA+ in the prompt: no
- bound: the no-revisit guard, no constraint

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them, one per bullet.

- Sequences
- Sequence module operators

## Constructs from other families, also exercised

- Cartesian product
- \A (universal quantifier, "forall")
- \E (existential quantifier, "exists")
- DOMAIN
- BOOLEAN and integer interval as sets
- Equality and inequality
- Booleans and logical operators
- Bullet-point boolean notation
- Implication
- Invariant (as a TLA+ operator, checked at every state)
- Init / Next / Spec (the pure-TLA+ spec skeleton)
- struct set
- struct literal

The last two are the record variant, which is measured.

## Operators with no inventory row

- `Len`
- `Append`
- `Seq(S)` in TypeOK
- `s[i]` with its 1-based origin, and `s[i][1]` on a pair inside a list
- `s[Len(s)]` as the last element
- `DOMAIN` of a sequence
- the one-element literal and the pair literal
- tuple against sequence: a pair indexed like a list

## Verify

| module | rc | distinct states |
|---|---|---|
| `RobotRef` | 0 | 653 |
| `RobotRecord` | 0 | 653 |
| `RobotDomainEdge` | 75 | 1 |
| `RobotFromStart` | 12 | 34 |

Each module has a config of its own name. The four configs are identical.
