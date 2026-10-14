# USES: temporal/03-alternation

Subject: Two processes taking turns at a shared resource, where a turn
variable decides who may enter and neither process can be starved.

rc: 0

## What the properties rest on

Both halves were probed. Dropping `WF_vars(Ask(p))` from `Fairness`
gives rc 13, so `NoStarvation` rests on every process going on asking.
Dropping the `turn = p` guard from `Enter` gives rc 12.

## Constructs

- []<> (always eventually)
- ' (prime, next-state value)
- [P]_x (box action formula)
- VARIABLE / VARIABLES
- vars (the all-variables tuple)
- Init / Next / Spec (the pure-TLA+ spec skeleton)
- action (formal definition)
- UNCHANGED
- nondeterministic action (\E form and disjunction form)
- WF_v(A) (weak fairness)
- fairness conjunct on Spec
- fairness on a subaction

## Constructs from other families, also exercised

- Operator definition
- EXTENDS (module import)
- Integers
- Strings
- Equality and inequality
- Bullet-point boolean notation
- Cardinality
- Set filter
- CHOOSE
- \A (universal quantifier, "forall")
- \E (existential quantifier, "exists")
- CONSTANT
- ASSUME
- set of model values
- function set
- function literal
- EXCEPT
- Invariant (as a TLA+ operator, checked at every state)
- PROPERTY (TLC model config: register a temporal property)
