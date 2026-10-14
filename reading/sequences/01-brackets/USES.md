# USES: sequences/01-brackets

Subject: A bracket string grown one character at a time, carrying a
counter of how many brackets are still open.

rc: 0

## What the properties rest on

rc 0 over 43 distinct states, 43 generated, depth 7. Forty-three is the
number of sound prefixes of length at most 6, and `Surplus` is why the
count has no slack in it: `open` is a function of `text`, so a state is
a text and nothing more.

`Surplus` rests on Push and Pop moving `open` with the character they
append. Flatten Push's `open' = open + 1` to `open' = open` and the run
gives rc 12 with `Surplus` named.

Pop's `open > 0` guard is load-bearing, and which obligation catches its
absence is the part worth reading. Delete the guard and the run gives
rc 12 against `TypeOK`, not against `PrefixSound`. `open` goes to -1 and
leaves `0..Limit` before any prefix has gone unbalanced. Widen
`TypeOK` to `open \in -Limit..Limit` as well and the same deletion gives
rc 12 against `PrefixSound`. So two separately named invariants sit one
behind the other on the same guard, and the cheaper one reports first.

That ordering is the argument for naming them separately rather than
conjoining them. One `INVARIANT` line would have reported this defect as
the conclusion instead of as the link that failed.

## Constructs

- Sequences
- Sequence module operators
- LAMBDA
- Strings
- \A (universal quantifier, "forall")
- Invariant (as a TLA+ operator, checked at every state)

## Constructs from other families, also exercised

- Operator definition
- EXTENDS (module import)
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
