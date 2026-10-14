# META: sequences/06-dispatch-board

- shape: prose, a board filtered by district
- time: 8 min
- lesson: a filter takes a test and keeps what passes, so the test says what stays
- shows TLA+ in the prompt: no
- bound: a guard of three lines on the board, the closed set finite by type

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them, one per bullet.

- Sequences
- Sequence module operators

## Constructs from other families, also exercised

- LAMBDA
- RECURSIVE
- Sets
- Set relational and algebraic operators
- Strings
- \A (universal quantifier, "forall")
- \E (existential quantifier, "exists")
- DOMAIN
- CONSTANT
- Invariant (as a TLA+ operator, checked at every state)
- Init / Next / Spec (the pure-TLA+ spec skeleton)
- UNCHANGED

`RECURSIVE` is the measured variant, not the answer.

## Operators with no inventory row

- `SelectSeq` with a `LAMBDA` test
- `Len`
- `Append`
- `Head` and `Tail`, in the recursive variant
- `\o`, in the recursive variant
- `Seq(S)` in TypeOK
- `s[i]` with its 1-based origin
- `DOMAIN` of a sequence
- the empty sequence literal

## Verify

| module | rc | distinct states |
|---|---|---|
| `DispatchRef` | 0 | 98 |
| `DispatchRecursive` | 0 | 98 |
| `DispatchFirstOnly` | 12 | 27 |
| `DispatchKeeps` | 12 | 9 |

Each module has a config of its own name. The four configs are identical.
