# META: sequences/01-triage-board

- shape: behavior table, nine steps over two lists, then the rule as a property
- time: 10 to 12 min. The property is the part that runs over.
- lesson: cutting an element out of the middle of a list, and a rule only an action formula can state
- shows TLA+ in the prompt: no
- bound: a guard on the board, a CONSTRAINT on the treated list

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them, one per bullet.

- Sequences
- Sequence module operators

## Constructs from other families, also exercised

- CHOOSE
- LET-IN
- \A (universal quantifier, "forall")
- \E (existential quantifier, "exists")
- DOMAIN
- action property
- [P]_x (box action formula)
- [] (always)
- ' (prime, next-state value)
- Implication
- CONSTANT
- Invariant (as a TLA+ operator, checked at every state)
- Init / Next / Spec (the pure-TLA+ spec skeleton)
- UNCHANGED

## Operators with no inventory row

The two rows above are the whole of this family in the inventory, and K011
covers every operator in the module at once. What the answer uses, one by
one, with no row of its own:

- `Len`
- `Append`
- `SubSeq`, the inclusive 1-based slice
- `\o`, concatenation, including with an empty slice
- `Seq(S)` as the set of all finite sequences, in TypeOK
- `s[i]` with its 1-based origin
- `DOMAIN` of a sequence as `1..Len(s)`
- the empty sequence literal
- `CONSTRAINT`, the cfg keyword

## Verify

| module | rc | distinct states |
|---|---|---|
| `TriageRef` | 0 | 7225 |
| `TriageRefAdmits` | 0 | 10 |
| `TriageFifo` | 13 | 50 |
| `TriageFifoAdmits` | 13 | 5 |
| `TriageSelect` | 0 | 7225 |
| `TriageSelectAdmits` | 13 | 10 |

`TriageRows.tla` is the table as data and has no cfg. Every other module
has a config of its own name.
