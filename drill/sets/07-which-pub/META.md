# META: sets/07-which-pub

- shape: prose prompt, two rules, a break-it step on the threshold
- time: 10 min
- lesson: a map and a filter both build a set from a set, and the state count can't tell them apart
- shows TLA+ in the prompt: no

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them, one per bullet.

- Set filter
- Set map
- Cardinality
- Cartesian product
- Set relational and algebraic operators
- Sets

## Constructs from other families, also exercised

- \A (universal quantifier, "forall")
- \E (existential quantifier, "exists")
- Implication
- Operator definition
- CONSTANT
- set of model values
- Invariant (as a TLA+ operator, checked at every state)
- Sequences
- Integers
- ' (prime, next-state value)
- deadlock (checking)

## Verify

| file | rc | distinct states |
|---|---|---|
| `verify/PubAnswer.tla` | 0 | 256 |
| `verify/PubMapTrapStrict.tla` | 0 | 256 |
| `verify/PubHalf.tla` | 12 | 181 |
| `verify/PubDoubleVote.tla` | 12 | 17 |
| `verify/PubMapTrap.tla` | 12 | 17 |

Each module has a config of the same name. Every config carries
`CHECK_DEADLOCK FALSE`, because all four friends having voted is a terminal
state the item wants. The two rows at 256 are the point of the item: the trap
and the answer explore the same space, so the count is no help. Reproduce with
`bash drill/sets/verify-item.sh drill/sets/07-which-pub`.

## Rubric

Fields and rationale: `drill/study/CLAUDE.md`. The `states` envelope is the
lowest and highest distinct count among the rc 0 rows above, so it was read
rather than reasoned. The `-because` lines and the fault list are owed by bead
`tla-sqym.3`.

- runs: yes
- fault: none
- states: 256..256
- obligations: 2
