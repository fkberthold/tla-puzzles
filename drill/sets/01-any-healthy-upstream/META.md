# META: sets/01-any-healthy-upstream

- shape: prose prompt, two rules and a colleague's claim to check
- time: 10 min
- lesson: an existential in an action branches, a chosen value doesn't
- shows TLA+ in the prompt: no

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them, one per bullet.

- CHOOSE
- SUBSET (powerset)
- Cartesian product
- Set map
- Set relational and algebraic operators
- Sets

## Constructs from other families, also exercised

- \E (existential quantifier, "exists")
- \A (universal quantifier, "forall")
- nondeterministic action (\E form and disjunction form)
- Sequences
- Invariant (as a TLA+ operator, checked at every state)
- CONSTANT
- set of model values
- deadlock (checking)

## Verify

| file | rc | distinct states |
|---|---|---|
| `verify/LbAnswer.tla` | 0 | 398 |
| `verify/LbClaim.tla` | 12 | 190 |
| `verify/LbChoose.tla` | 0 | 189 |
| `verify/LbAnyUpstream.tla` | 12 | 32 |
| `verify/LbKeepWaiting.tla` | 12 | 31 |
| `verify/LbEmptyHealth.tla` | 11 | 172 |
| `verify/LbSubseteqInit.tla` | 0 | 398 |

Each module has a config of the same name. `LbClaim` extends `LbAnswer`
and only its config differs. Reproduce with
`bash drill/sets/verify-item.sh drill/sets/01-any-healthy-upstream`.

## Rubric

Fields and rationale: `drill/study/CLAUDE.md`. The `states` envelope is the
lowest and highest distinct count among the rc 0 rows above, so it was read
rather than reasoned. The `-because` lines and the fault list are owed by bead
`tla-sqym.3`.

- runs: yes
- fault: none
- states: 189..398
- obligations: 2
