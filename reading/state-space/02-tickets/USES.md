# USES: state-space/02-tickets

Subject: Three players take numbered tickets from a counter that never
stops climbing, and a CONSTRAINT is what keeps the search finite.

rc: 0

## What the properties rest on

rc 0 over 79 distinct states at `Limit = 6`, with deadlock checking on.

The CONSTRAINT is doing the work. Comment it out and TLC doesn't finish,
so `verdict.sh --timeout 20` returns 124. Raise the bound to 9 and the
same run finds 127 distinct states instead of 79. The line sets the size
of the search rather than describing it. So rc 0 means no violation
among the behaviours that stay under the bound, and I think that's the
part worth holding onto. A CONSTRAINT buys termination and charges
coverage for it.

Two probes say what the deadlock check covers here. At `Limit = 0` the
only move available is a Take, the constraint prunes it, and the run
still returns 0, so TLC doesn't read a pruned frontier as a wedged
machine. Drop `Take` from `Next` and the initial state really has no
successor, which returns 11. The second probe is how I know the first
one wasn't measuring a check that was switched off.

Change `next' = next + 1` to `next' = next` and the run returns 12 with
`Issued` named as the invariant that broke. Five separate INVARIANT
lines are what buy that label. One conjunction would have reported the
same defect as the conclusion rather than as the link that failed.

`Orderly` can fail too. Let the Leave step write `serving' = serving + 2`
and the run returns 13, not 12, because a boxed action goes through the
implied-action channel whatever its counterexample looks like.

## Constructs

- CONSTANT
- model value
- set of model values
- Invariant (as a TLA+ operator, checked at every state)
- deadlock (checking)
- PROPERTY (TLC model config: register a temporal property)

`CONSTRAINT` carries this item and `drill/INVENTORY.md` has no row for
it, so nothing above claims one.

## Constructs from other families, also exercised

- Operator definition
- EXTENDS (module import)
- Integers
- Equality and inequality
- Implication
- Bullet-point boolean notation
- Sets
- Set filter
- Set relational and algebraic operators
- Cardinality
- \A (universal quantifier, "forall")
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
- action property
- UNCHANGED
