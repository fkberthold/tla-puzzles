# USES: state-space/03-chips

Subject: Four players pass chips to whoever holds fewer, with deadlock
checking on and the claim that the table never stalls.

rc: 0

## What the properties rest on

rc 0 over 120 distinct states. 120 is every way to split 7 chips among 4
players, so the search reaches all of them.

The ASSUME is the whole argument. Set `Stake = 8` and the run returns 10
before TLC generates a state. Drop the ASSUME as well and the level
table is reachable, which returns 12 with `SomeoneCanPass` named.
Comment that invariant out too and the same defect returns 11. So the
invariant and the deadlock check are two routes to one fact, and the
invariant gets there first.

One ASSUME line does two jobs, which took me a moment to see. It rules
out the level table, and it rules out a single player as well, since
anything mod 1 is 0. `Player = {p1}` returns 10 against that one line.
An earlier draft carried a separate `Cardinality(Player) > 1`, and
measurement said it was redundant.

`Pass` has no `p # q` guard and doesn't need one, because a pile isn't
larger than itself.

## Constructs

- CONSTANT
- ASSUME
- set of model values
- Invariant (as a TLA+ operator, checked at every state)
- deadlock (checking)

## Constructs from other families, also exercised

- Operator definition
- EXTENDS (module import)
- IF-THEN-ELSE
- Integers
- Equality and inequality
- Bullet-point boolean notation
- LET-IN
- RECURSIVE
- CHOOSE
- Sets
- Set relational and algebraic operators
- Cardinality
- BOOLEAN and integer interval as sets
- \E (existential quantifier, "exists")
- function set
- function literal
- EXCEPT
- VARIABLE / VARIABLES
- vars (the all-variables tuple)
- Init / Next / Spec (the pure-TLA+ spec skeleton)
- action (formal definition)
- nondeterministic action (\E form and disjunction form)
- ' (prime, next-state value)
- [P]_x (box action formula)
