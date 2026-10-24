# META: sets/05-leases

- shape: prose prompt, two rules, a break-it step on the free check
- time: 10 min
- lesson: a map builds a new set, a filter keeps part of one, and they swap silently
- shows TLA+ in the prompt: no

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them, one per bullet.

- Set map
- Set filter
- Cardinality
- Cartesian product
- Set relational and algebraic operators
- Sets

## Constructs from other families, also exercised

- \A (universal quantifier, "forall")
- \E (existential quantifier, "exists")
- Sequences
- Operator definition
- CONSTANT
- set of model values
- Invariant (as a TLA+ operator, checked at every state)

## Verify

| file | rc | distinct states |
|---|---|---|
| `verify/LeaseAnswer.tla` | 0 | 61 |
| `verify/LeaseNoFreeCheck.tla` | 12 | 11 |
| `verify/LeaseFilterTrap.tla` | 0 | 343 |
| `verify/LeaseNoQuotaCheck.tla` | 12 | 38 |
| `verify/LeaseMapTrap.tla` | 0 | 64 |

Each module has a config of the same name. Reproduce with
`bash drill/sets/verify-item.sh drill/sets/05-leases`.

## Rubric

Fields and rationale: `drill/study/CLAUDE.md`. The `states` envelope is the
lowest and highest distinct count among the rc 0 rows above, so it was read
rather than reasoned. The `-because` lines and the fault list are owed by bead
`tla-sqym.3`.

- runs: yes
- fault: none
- states: 61..343
- obligations: 2
