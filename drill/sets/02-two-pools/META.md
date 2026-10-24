# META: sets/02-two-pools

- shape: prose prompt, three rules, one of them about a named individual
- time: 12 min
- lesson: a count says how many and a set says who, and two of the rules need who
- shows TLA+ in the prompt: no

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them, one per bullet.

- Sets
- Set relational and algebraic operators
- Cardinality
- Set filter
- Set map
- Cartesian product
- SUBSET (powerset)

## Constructs from other families, also exercised

- \E (existential quantifier, "exists")
- \A (universal quantifier, "forall")
- Implication
- Operator definition
- ASSUME
- CONSTANT
- set of model values
- Invariant (as a TLA+ operator, checked at every state)
- Sequences
- function set
- function literal
- EXCEPT
- IF-THEN-ELSE
- Strings
- Integers
- UNCHANGED
- ' (prime, next-state value)

## Verify

| file | rc | distinct states |
|---|---|---|
| `verify/PoolsSets.tla` | 0 | 49 |
| `verify/PoolsPairs.tla` | 0 | 49 |
| `verify/PoolsCrew.tla` | 0 | 49 |
| `verify/PoolsWhere.tla` | 0 | 49 |
| `verify/PoolsCounts.tla` | 0 | 9 |
| `verify/PoolsNoCap.tla` | 12 | 26 |
| `verify/PoolsStayPut.tla` | 12 | 11 |
| `verify/PoolsTraineeAlone.tla` | 12 | 5 |

Each module has a config of the same name. `PoolsCounts` is the only one with
a different constant list, since it holds a guard count rather than the guards.
Reproduce with `bash drill/sets/verify-item.sh drill/sets/02-two-pools`.

## Rubric

Fields and rationale: `drill/study/CLAUDE.md`. The `states` envelope is the
lowest and highest distinct count among the rc 0 rows above, so it was read
rather than reasoned. The `-because` lines and the fault list are owed by bead
`tla-sqym.3`.

- runs: yes
- fault: none
- states: 9..49
- obligations: 3
