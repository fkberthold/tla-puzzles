# META: sequences/04-deck-log

- shape: behavior table, seven steps over two lists, then a rule about positions
- time: 10 min
- lesson: a prefix moves as two slices and a join, and the split is at k and k plus one
- shows TLA+ in the prompt: no
- bound: a guard on writing past the last entry, and the end of the voyage is a terminal state

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them, one per bullet.

- Sequences
- Sequence module operators

## Constructs from other families, also exercised

- \A (universal quantifier, "forall")
- \E (existential quantifier, "exists")
- DOMAIN
- BOOLEAN and integer interval as sets
- CONSTANT
- Integers
- Invariant (as a TLA+ operator, checked at every state)
- Init / Next / Spec (the pure-TLA+ spec skeleton)
- UNCHANGED
- deadlock (checking)

## Operators with no inventory row

- `SubSeq`, twice, with the split at k and k plus one
- `\o`, joining a batch onto a list
- `Append`
- `Len`
- `Seq(S)` in TypeOK
- `s[i]` with its 1-based origin, in the rule
- `DOMAIN` of a sequence
- `Head` and `Tail`, in the one-per-step neighbor
- the empty sequence literal

## Verify

| module | rc | distinct states |
|---|---|---|
| `DeckLogRef` | 0 | 21 |
| `DeckLogRefAdmits` | 0 | 8 |
| `DeckLogOffByOne` | 12 | 4 |
| `DeckLogOffByOneAdmits` | 13 | 5 |
| `DeckLogOverwrite` | 12 | 12 |
| `DeckLogOverwriteAdmits` | 13 | 8 |
| `DeckLogHeadOnly` | 0 | 21 |
| `DeckLogHeadOnlyAdmits` | 13 | 5 |

`DeckLogRows.tla` is the table as data and has no cfg. Every other module
has a config of its own name.
