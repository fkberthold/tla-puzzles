# META: sets/04-convoys

- shape: prose prompt, three rules, a collection whose members are sets
- time: 12 min
- lesson: the flattening union and the binary union do different jobs and swap silently
- shows TLA+ in the prompt: no

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them, one per bullet.

- Sets
- Set relational and algebraic operators
- SUBSET (powerset)
- Cardinality

## Constructs from other families, also exercised

- \E (existential quantifier, "exists")
- \A (universal quantifier, "forall")
- Implication
- Operator definition
- CONSTANT
- set of model values
- Invariant (as a TLA+ operator, checked at every state)
- Sequences
- Integers
- UNCHANGED
- ' (prime, next-state value)
- deadlock (checking)

## Keywords with no inventory row

Named as the module spells them.

- UNION

## Verify

| file | rc | distinct states |
|---|---|---|
| `verify/ConvoyAnswer.tla` | 0 | 150 |
| `verify/ConvoyMergeFlat.tla` | 76 | 20 |
| `verify/ConvoyCupSpelling.tla` | 150 | parse error |
| `verify/ConvoyEmptySubseteq.tla` | 12 | none logged |
| `verify/ConvoyMergeKeeps.tla` | 12 | 18 |

Each module has a config of the same name. Every config carries
`CHECK_DEADLOCK FALSE`, because an empty road with an empty depot is a terminal
state the item wants. `ConvoyEmptySubseteq` fails during the initial-state
computation, which is before TLC prints a count. Reproduce with
`bash drill/sets/verify-item.sh drill/sets/04-convoys`.
