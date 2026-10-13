# USES: modules/03-fences

Subject: Two gates cut a corridor into three segments, and each segment is an
instance of one interval library that assumes its own bounds are in order.

rc: 0

## Constructs

- EXTENDS (module import)
- INSTANCE
- named instance
- ! (namespace lookup)
- INSTANCE ... WITH (<- constant substitution)
- LOCAL (definition modifier)

## What the measurements say

N = 7 gives rc 0 over 28 distinct states, which is the whole `a <= b`
triangle, so every degenerate gate position is reached.

`Mid` really does invert. Asserting `Mid!Cells # {}` instead gives rc 12 on a
trace that reaches a = 6, b = 7, where `Mid` is `INSTANCE Seg WITH Lo <- 7,
Hi <- 6`. That instance breaks `Seg`'s own `ASSUME Lo <= Hi` and the run is
still rc 0.

An ASSUME does not cross an INSTANCE on this build, and both halves were
measured here. `ASSUME 99 <= 1` in a root module gives rc 10. The same
assumption reached through `INSTANCE Band WITH Lo <- 99, Hi <- 1` against
`ASSUME Lo <= Hi` gives rc 0 and prints nothing. So a library that guards its
constants with an ASSUME guards nothing once anybody instantiates it.

`Count`'s clamp is load-bearing rather than defensive. Drop the IF and
`Counted` fails at rc 12 with a = b = 7, where the hidden `Span` is -2.

`LOCAL` hides `Span` from the caller, so only the clamped `Count` crosses the
boundary. Writing `Below!Span` gives rc 150 and "Unknown operator: `Span'".

`Disjoint` is not declared, because I think `Covered` and `Counted` together
already carry it: five pieces summing to N elements cannot overlap inside a
union of N.

## Constructs from other families, also exercised

- Operator definition
- Integers
- IF-THEN-ELSE
- Equality and inequality
- Implication
- Bullet-point boolean notation
- Cardinality
- Set relational and algebraic operators
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
- UNCHANGED
- Invariant (as a TLA+ operator, checked at every state)
