# USES: core/01-nim

Subject: Three heaps of seven stones. A move takes any number of stones
from one heap, and the bitwise exclusive-or of the three sizes is what
the properties watch.

rc: 0

## What the properties rest on

`NoEscape` rests on a move touching one heap only. Adding an arm that
takes a stone from two heaps at once gives rc 13. `ZeroIsOneMoveAway`
rests on a move being allowed to take more than one stone, and
narrowing the escape to `k = a - 1` gives rc 12.

## Constructs

- Operator definition
- IF-THEN-ELSE
- Equality and inequality
- Integers
- Booleans and logical operators
- Bullet-point boolean notation
- Implication
- LET-IN
- \E (existential quantifier, "exists")
- RECURSIVE
- Custom binary operator

## Constructs from other families, also exercised

- EXTENDS (module import)
- CONSTANT
- ASSUME
- BOOLEAN and integer interval as sets
- VARIABLE / VARIABLES
- vars (the all-variables tuple)
- Init / Next / Spec (the pure-TLA+ spec skeleton)
- action (formal definition)
- nondeterministic action (\E form and disjunction form)
- ' (prime, next-state value)
- [P]_x (box action formula)
- action property
- UNCHANGED
- Invariant (as a TLA+ operator, checked at every state)
- PROPERTY (TLC model config: register a temporal property)
- deadlock (checking)
