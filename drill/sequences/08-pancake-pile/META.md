# META: sequences/08-pancake-pile

- shape: behaviour table, four flips of one list, then a rule
- time: 8 min
- lesson: a list is a function on 1..n, so an operation the module lacks is a function literal, and the mirror index is 1-based
- shows TLA+ in the prompt: no
- bound: four pancakes, nothing grows

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them, one per bullet.

- Sequences
- Sequence module operators

## Constructs from other families, also exercised

- function literal
- function set
- IF-THEN-ELSE
- RECURSIVE
- \A (universal quantifier, "forall")
- \E (existential quantifier, "exists")
- DOMAIN
- BOOLEAN and integer interval as sets
- CONSTANT
- Invariant (as a TLA+ operator, checked at every state)
- Init / Next / Spec (the pure-TLA+ spec skeleton)

`RECURSIVE` is the measured variant, not the answer.

## Operators with no inventory row

- `Len`
- `s[i]` with its 1-based origin, and the index-0 failure
- `DOMAIN` of a sequence
- `Seq(S)` in TypeOK
- a function literal over `1..Len(s)` as a way to build a list
- `Head`, `Tail`, `Append`, `SubSeq` and `\o`, in the recursive variant
- tuple against function: `[1..N -> 1..N]` enumerated as the arrangements

## Verify

| module | rc | distinct states |
|---|---|---|
| `PileRef` | 0 | 24 |
| `PileRefAdmits` | 0 | 5 |
| `PileRecursive` | 0 | 24 |
| `PileOffByOne` | 75 | 24 |
| `PileWhole` | 0 | 24 |
| `PileWholeAdmits` | 13 | 2 |

`PileRows.tla` is the table as data and has no cfg. Every other module has
a config of its own name.
