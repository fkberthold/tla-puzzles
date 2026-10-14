# META: sequences/07-pneumatic-tube

- shape: prose, a queue with an order rule that needs history
- time: 8 to 10 min
- lesson: a rule about order needs what the queue has forgotten, and the rule is one concatenation
- shows TLA+ in the prompt: no
- bound: a CONSTRAINT on the sent list, no guard

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them, one per bullet.

- Sequences
- Sequence module operators

## Constructs from other families, also exercised

- \E (existential quantifier, "exists")
- Strings
- CONSTANT
- Equality and inequality
- Invariant (as a TLA+ operator, checked at every state)
- Init / Next / Spec (the pure-TLA+ spec skeleton)
- UNCHANGED

## Operators with no inventory row

- `Append`
- `Head`
- `Tail`
- `Len`
- `\o`, as the whole of the rule
- `Seq(S)` in TypeOK
- `SubSeq`, in the derived variant
- the empty sequence literal
- `CONSTRAINT`, the cfg keyword

## Verify

| module | rc | distinct states |
|---|---|---|
| `TubeRef` | 0 | 129 |
| `TubeDerived` | 0 | 129 |
| `TubeLifo` | 12 | 15 |
| `TubeSendFront` | 12 | 5 |
| `TubeCountOnly` | 0 | 57 |

Each module has a config of its own name.
