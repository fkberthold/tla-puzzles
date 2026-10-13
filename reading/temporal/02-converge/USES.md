# USES: temporal/02-converge

Subject: A ring of nodes where each one copies its left neighbor's value
whenever that value is larger, with weak fairness on every copy step.

rc: 0

Weak fairness is what buys `Settles`. Dropping the `Fairness` conjunct
from `Spec` gives rc 13. Running with deadlock checking on gives rc 11,
which is why the `.cfg` says `CHECK_DEADLOCK FALSE`.

## Constructs

- <>[] (eventually always)
- action property
- ' (prime, next-state value)
- [P]_x (box action formula)
- VARIABLE / VARIABLES
- vars (the all-variables tuple)
- Init / Next / Spec (the pure-TLA+ spec skeleton)
- action (formal definition)
- nondeterministic action (\E form and disjunction form)
- WF_v(A) (weak fairness)
- fairness conjunct on Spec
- fairness on a subaction

## Constructs from other families, also exercised

- Operator definition
- EXTENDS (module import)
- Integers
- Equality and inequality
- Bullet-point boolean notation
- BOOLEAN and integer interval as sets
- \A (universal quantifier, "forall")
- \E (existential quantifier, "exists")
- CONSTANT
- ASSUME
- function set
- function literal
- EXCEPT
- Invariant (as a TLA+ operator, checked at every state)
- PROPERTY (TLC model config: register a temporal property)
- deadlock (checking)
