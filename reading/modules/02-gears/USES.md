# USES: modules/02-gears

Subject: A 12-tooth wheel meshed with a smaller one, where the small wheel's
position is read off the big wheel's rather than tracked on its own.

rc: 0

## Constructs

- EXTENDS (module import)
- INSTANCE
- named instance
- ! (namespace lookup)
- INSTANCE ... WITH (<- constant substitution)
- partial parameterization

`Big == INSTANCE Wheel WITH K <- 12` leaves `n` out of the WITH clause, so the
implicit `n <- n` binds the outer variable. That binding drives the whole run,
since `Init` and `Click` are both `Big!` lookups.

## What the measurements say

Teeth = 4 gives rc 0 over 12 distinct states, one per tooth of the big wheel.

`SmallTurns` needs the tooth counts to divide. At Teeth = 5 the root ASSUME
catches it first and gives rc 10, which is worth having on its own: an ASSUME
in the root module is checked. Relax that ASSUME and Teeth = 5 gives rc 13 on
`Small!WSpec`'s box action. The break is at the wrap, where the big wheel
returns to tooth 0 and the small wheel is at 12 mod 5.

The two instances are not symmetric, and I think that is the part to work out
here. `Big!WSpec` fails at rc 13 even at Teeth = 4, because `Spin` moves the
big wheel by 4 teeth rather than by 1. The small wheel survives a step the big
wheel cannot, and what lets it is the `_n` subscript in `[][WNext]_n` once `n`
has been substituted.

## Constructs from other families, also exercised

- Operator definition
- Integers
- Equality and inequality
- Implication
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
- action property
- Invariant (as a TLA+ operator, checked at every state)
- PROPERTY (TLC model config: register a temporal property)
