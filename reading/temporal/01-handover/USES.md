# USES: temporal/01-handover

Subject: A baton that moves between sites only when somebody has asked
for it, with weak fairness on the granting step alone.

rc: 0

## Constructs

- WF_v(A) (weak fairness)
- fairness conjunct on Spec
- fairness on a subaction
- ~> (leads-to)
- action property
- PROPERTY (TLC model config: register a temporal property)

## Constructs from other families, also exercised

- Operator definition
- Booleans and logical operators
- Bullet-point boolean notation
- Equality and inequality
- Cardinality
- Set relational and algebraic operators
- \E (existential quantifier, "exists")
- CONSTANT
- ASSUME
- set of model values
- VARIABLE / VARIABLES
- vars (the all-variables tuple)
- Init / Next / Spec (the pure-TLA+ spec skeleton)
- action (formal definition)
- nondeterministic action (\E form and disjunction form)
- ' (prime, next-state value)
- [P]_x (box action formula)
- UNCHANGED
- Invariant (as a TLA+ operator, checked at every state)
