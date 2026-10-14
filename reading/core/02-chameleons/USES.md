# USES: core/02-chameleons

Subject: Six chameleons in three colors, starting one, two and three.
Two of different colors meet and both take on the third, and they
never all end up matching.

rc: 0

## What the properties rest on

`Spread` rests on the third color gaining two rather than one.
Changing that arm of the CASE to `count[k] + 1` gives rc 12.
`NeverOneColor` rests on the starting counts, and `<<2, 2, 2>>` in
place of `<<1, 2, 3>>` gives rc 12 with all six reaching one color.

Every reachable state has a successor, measured by rerunning with
`--check-deadlock` at rc 0, so the .cfg carries no `CHECK_DEADLOCK`
line. The nine reachable states are the whole run.

## Constructs

- Operator definition
- Equality and inequality
- Integers
- Booleans and logical operators
- Bullet-point boolean notation
- Implication
- \A (universal quantifier, "forall")
- \E (existential quantifier, "exists")
- CASE

## Constructs from other families, also exercised

- EXTENDS (module import)
- BOOLEAN and integer interval as sets
- function literal
- function set
- VARIABLE / VARIABLES
- vars (the all-variables tuple)
- Init / Next / Spec (the pure-TLA+ spec skeleton)
- action (formal definition)
- nondeterministic action (\E form and disjunction form)
- ' (prime, next-state value)
- [P]_x (box action formula)
- Invariant (as a TLA+ operator, checked at every state)
