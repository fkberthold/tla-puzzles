# USES: sequences/01-brackets

Subject: A bracket string grown one character at a time, carrying a
counter of how many brackets are still open.

rc: 0

## Constructs

- Sequences
- Sequence module operators
- LAMBDA
- Strings
- \A (universal quantifier, "forall")
- Invariant (as a TLA+ operator, checked at every state)

## Constructs from other families, also exercised

- Operator definition
- Integers
- Equality and inequality
- Bullet-point boolean notation
- BOOLEAN and integer interval as sets
- CONSTANT
- ASSUME
- VARIABLE / VARIABLES
- vars (the all-variables tuple)
- Init / Next / Spec (the pure-TLA+ spec skeleton)
- action (formal definition)
- nondeterministic action (\E form and disjunction form)
- ' (prime, next-state value)
- [P]_x (box action formula)
- deadlock (checking)
