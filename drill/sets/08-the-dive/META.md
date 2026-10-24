# META: sets/08-the-dive

- shape: prose prompt, two rules, a break-it step on the all-in guard
- time: 8 min
- lesson: the subset relation is the weak spelling of an all-or-nothing rule
- shows TLA+ in the prompt: no

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them, one per bullet.

- Set relational and algebraic operators
- Sets

## Constructs from other families, also exercised

- \E (existential quantifier, "exists")
- Implication
- CONSTANT
- set of model values
- deadlock (checking)
- Invariant (as a TLA+ operator, checked at every state)
- UNCHANGED

## Verify

| file | rc | distinct states |
|---|---|---|
| `verify/DiveAnswer.tla` | 0 | 321 |
| `verify/DiveEarlyDescent.tla` | 12 | 13 |
| `verify/DiveWeakRule.tla` | 0 | 625 |
| `verify/DiveDescendAfterCall.tla` | 12 | 242 |
| `verify/DiveCallFromBelow.tla` | 12 | 227 |

Each module has a config of the same name. Reproduce with
`bash drill/sets/verify-item.sh drill/sets/08-the-dive`.

## Rubric

Fields and rationale: `drill/study/CLAUDE.md`. The `states` envelope is the
lowest and highest distinct count among the rc 0 rows above, so it was read
rather than reasoned. The `-because` lines and the fault list are owed by bead
`tla-sqym.3`.

- runs: yes
- fault: none
- states: 321..625
- obligations: 2
