# META: sequences/05-undo-history

- shape: behaviour table, eight steps of one list, then a length bound
- time: 8 min
- lesson: a bounded history uses both ends of a list, and the module gives you an operator for only one of them
- shows TLA+ in the prompt: no
- bound: the drop when full, which is a guard inside the action, no constraint

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them, one per bullet.

- Sequences
- Sequence module operators

## Constructs from other families, also exercised

- IF-THEN-ELSE
- \E (existential quantifier, "exists")
- Strings
- CONSTANT
- Invariant (as a TLA+ operator, checked at every state)
- Init / Next / Spec (the pure-TLA+ spec skeleton)

## Operators with no inventory row

- `Append`
- `Tail`
- `SubSeq`, stopping one short of the end
- `Len`
- `Seq(S)` in TypeOK, with the bound that makes it finite
- `\o`, in the newest-first variant
- the empty sequence literal and the one-element literal
- `SubSeq` past the end as a TLC error, exit 255

## Verify

| module | rc | distinct states |
|---|---|---|
| `UndoRef` | 0 | 85 |
| `UndoRefAdmits` | 0 | 8 |
| `UndoTailPop` | 0 | 85 |
| `UndoTailPopAdmits` | 13 | 6 |
| `UndoAppendOnly` | 12 | 86 |
| `UndoRefuseFull` | 0 | 85 |
| `UndoRefuseFullAdmits` | 13 | 5 |
| `UndoNewestFirst` | 0 | 85 |
| `UndoNewestFirstAdmits` | 13 | 3 |
| `UndoMirror` | 255 | 1 |
| `UndoMirrorAdmits` | 255 | 2 |

`UndoRows.tla` is the table as data and has no cfg. Every other module has
a config of its own name.
