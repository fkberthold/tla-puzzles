# USES: sets/02-antichain

Subject: A family of subsets grown one subset at a time, where a new member
has to be incomparable with every member already in.

rc: 0

## What the properties rest on

168 distinct states, 455 generated, depth 7, under a second. 168 is every
antichain on a four-element set, so the run reaches all of them.

`Widest` is tight rather than slack. Lower its bound by one, to
`Cardinality(Middle) - 1`, and the run gives rc 12. So a family of six is
reached and the bound is the smallest one that holds.

`Nests` needs both of its arms. Cut it to `a \subseteq b` and the run gives
rc 12, because a superset of a member then passes the guard and `Diagonal`
picks up the extra pair.

`Narrowing` has a direction. Reverse it to `[][Open \subseteq Open']_vars`
and the run gives rc 13, which is the implied-action channel in
`harness/verdict.sh`'s table rather than a safety violation.

The `ASSUME` is load-bearing. Point the .cfg at a three-element `Item` and
the run gives rc 10. `Middle` is empty for an odd `Item`, so `Widest` would
bound the family at zero, and the assumption stops the run before any
invariant is evaluated.

## Constructs

- Sets
- Set relational and algebraic operators
- Cardinality
- Cartesian product
- SUBSET (powerset)
- Set filter

## Constructs from other families, also exercised

- Operator definition
- EXTENDS (module import)
- Integers
- Booleans and logical operators
- Equality and inequality
- Bullet-point boolean notation
- \A (universal quantifier, "forall")
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
- action property
- deadlock (checking)
- Invariant (as a TLA+ operator, checked at every state)
- PROPERTY (TLC model config: register a temporal property)
