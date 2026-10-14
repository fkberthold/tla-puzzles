# USES: temporal/01-handover

Subject: A baton that moves between sites only when somebody has asked
for it, with weak fairness on the granting step alone.

rc: 0

## What the properties rest on

rc 0 over 6 distinct states, 12 generated. Six is three sites against
two values of `want`, so the search is complete.

The two properties rest on different things and fail through different
channels, which is the part worth working out here.

`Served` rests on `WF_vars(Grant)`. Drop the conjunct from `Spec` and
the run gives rc 13, reported as `Temporal property Served was
violated`: without it the baton may simply never move, and `want` stays
true forever.

`MovesOnlyWhenAsked` rests on Grant's `want` guard. Delete the guard and
the run also gives rc 13, but reported as `Action property
MovesOnlyWhenAsked is violated`. Both are rc 13 because a `~>` and a
`[][A]_vars` both need an infinite behaviour, which is the split
`harness/verdict.sh` records between 12 and 13.

The `ASSUME Cardinality(Site) > 1` is load-bearing rather than tidy.
Point the .cfg at `Site = {s1}` and the run gives rc 10 before a state
is generated. With one site `Site \ {holder}` is empty, so Grant could
never fire and `Served` would fail on a model nobody meant to write.

## Constructs

- WF_v(A) (weak fairness)
- fairness conjunct on Spec
- fairness on a subaction
- ~> (leads-to)
- action property
- PROPERTY (TLC model config: register a temporal property)

## Constructs from other families, also exercised

- Operator definition
- EXTENDS (module import)
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
