# USES: state-space/01-quorums

Subject: Four processes each cast one vote, and any majority of them can
record an outcome. Outcomes accumulate in a set and are never removed.

rc: 0

## Constructs

- SUBSET (powerset)
- Set filter
- Cardinality
- set of model values
- Invariant (as a TLA+ operator, checked at every state)
- deadlock (checking)

## Constructs from other families, also exercised

- Operator definition
- Integers
- Strings
- Equality and inequality
- Bullet-point boolean notation
- Set relational and algebraic operators
- function set
- function literal
- EXCEPT
- \A (universal quantifier, "forall")
- \E (existential quantifier, "exists")
- CONSTANT
- VARIABLE / VARIABLES
- vars (the all-variables tuple)
- Init / Next / Spec (the pure-TLA+ spec skeleton)
- action (formal definition)
- nondeterministic action (\E form and disjunction form)
- ' (prime, next-state value)
- [P]_x (box action formula)
- action property
- UNCHANGED
- PROPERTY (TLC model config: register a temporal property)
