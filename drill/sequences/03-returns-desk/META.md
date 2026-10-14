# META: sequences/03-returns-desk

- shape: prose, one state with three encodings, measured against each other
- time: 10 min for one encoding, more to write all three
- lesson: a list is extra state when the prompt never asked for order, and what a set makes free a list makes a rule
- shows TLA+ in the prompt: no
- bound: three books, nothing grows

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them, one per bullet.

- Sequences
- Sequence module operators

## Constructs from other families, also exercised

- Sets
- Set relational and algebraic operators
- function set
- function literal
- EXCEPT
- \A (universal quantifier, "forall")
- \E (existential quantifier, "exists")
- DOMAIN
- Strings
- model value
- set of model values
- CONSTANT
- Implication
- Invariant (as a TLA+ operator, checked at every state)
- Init / Next / Spec (the pure-TLA+ spec skeleton)
- UNCHANGED

## Operators with no inventory row

- `Len`
- `Append`
- `SubSeq` twice, joined with `\o`, to remove one index
- `Seq(S)` in TypeOK
- `s[i]` with its 1-based origin
- `DOMAIN` of a sequence, as the range of a membership search
- the empty sequence literal

## Verify

| module | rc | distinct states |
|---|---|---|
| `DeskSeq` | 0 | 38 |
| `DeskSet` | 0 | 27 |
| `DeskFun` | 0 | 27 |
| `DeskSeqStaysOut` | 12 | 5 |

Each module has a config of its own name.
