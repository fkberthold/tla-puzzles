# USES: temporal/05-break

Subject: Two orchestral players who begin and end playing as they
please, and a conductor whose call for a break bars any fresh beginning
until the room has fallen quiet.

rc: 0

## What the properties rest on

rc 0 over 8 distinct states, 18 generated. Eight is two values of
`asked` against the four ways two players can be playing, so the search
is complete.

`BreakArrives` asks for a state where nobody is playing, and that is a
state two independent players have to reach at the same instant.
Nothing in `Fairness` promises one. Weak fairness is a promise about a
single action, so `WF_vars(Stop(p))` promises that this player puts the
instrument down, and two such promises do not add up to a moment when
both have, because either is free to pick it up again. What makes them
add up is the `~asked` guard on `Start`. Once the conductor has asked,
`playing` can only shrink, so the separate promises accumulate instead
of racing.

`NoFreshStart` is that shrinking written as an action property, so the
lemma `BreakArrives` rests on is checked rather than argued.

Delete the `~asked` guard from `Start` and the run gives rc 13, reported
as `Action property NoFreshStart is violated`, because the lemma fails
first. Take `PROPERTY NoFreshStart` out of the .cfg and the same module
gives rc 13 again, now as `Temporal property BreakArrives was
violated`, over a four-state lasso in which each player starts and
stops forever and the two are never idle together.

That lasso is why no fairness assumption rescues the property. Replace
the whole of `Fairness` with `SF_vars` on all four actions and the run
is still rc 13 on `BreakArrives`, because every action is taken
infinitely often in the lasso, so strong fairness has nothing to object
to. Strengthening fairness inside the working module is just as inert.
Swap `WF_vars(Stop(p))` for `SF_vars(Stop(p))` and the run is rc 0, the
same verdict the weak form already bought.

The two fairness conjuncts that are there do carry weight. Drop
`\A p \in Player : WF_vars(Stop(p))` and the run gives rc 13 on
`BreakArrives`, since nobody is then obliged to stop. `Resume` is the
only action whose guard names the joint state, and dropping its
`AllIdle` guard gives rc 13 as well, because a break that can be lifted
early puts `Start` back in play and the lasso comes back.

## Constructs

- ~> (leads-to)
- WF_v(A) (weak fairness)
- fairness conjunct on Spec
- fairness on a subaction
- action property
- ' (prime, next-state value)
- [P]_x (box action formula)
- VARIABLE / VARIABLES
- vars (the all-variables tuple)
- Init / Next / Spec (the pure-TLA+ spec skeleton)
- action (formal definition)
- nondeterministic action (\E form and disjunction form)
- UNCHANGED

## Constructs from other families, also exercised

- Operator definition
- Equality and inequality
- Booleans and logical operators
- Implication
- Bullet-point boolean notation
- Sets
- BOOLEAN and integer interval as sets
- \A (universal quantifier, "forall")
- \E (existential quantifier, "exists")
- CONSTANT
- set of model values
- function set
- function literal
- EXCEPT
- Invariant (as a TLA+ operator, checked at every state)
- PROPERTY (TLC model config: register a temporal property)
