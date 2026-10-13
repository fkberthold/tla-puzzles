# USES: pluscal/06-bubble

Subject: Four slots holding values 1 to 4, starting anywhere, where the
only move swaps an adjacent pair that's out of order.

rc: 0

Translated with `pcal -lineWidth 72 -nocfg`. The translation is committed,
so the module checks as it stands.

## Measured probes

`Shrinks` says one swap removes exactly one inversion, counted over all
pairs rather than adjacent ones. That's the termination argument, and
`Inver` quantifies over `Pairs` for exactly that reason.

- Adding `[][a' # a => Cardinality(Bad') <= Cardinality(Bad)]_vars` gives
  rc 13.
- The same property at length 3 gives rc 0.

So the adjacent count is not a decreasing measure, and at length 3 you
can't tell. `<<2,4,1,3>>` swaps to `<<2,1,4,3>>` and goes from one adjacent
inversion to two. The all-pairs count falls from 3 to 2 across that step,
which is what `Shrinks` watches.

`define` earns its place here. `Bad` is read by the `while` guard, by the
`with`, and by `Settled`, so putting it inside the algorithm is the only
way the guard and the property share one definition.

## Constructs

- --algorithm block
- := assignment
- || simultaneous assignment
- label
- label-as-action encoding
- while
- with
- nondeterministic with
- \in on a variable declaration
- define block (PlusCal)
- pc (PlusCal's label-tracking variable)
- Terminating

## Constructs from other families, also exercised

- Operator definition
- EXTENDS (module import)
- IF-THEN-ELSE
- Integers
- Strings
- Equality and inequality
- Implication
- Bullet-point boolean notation
- Sets
- Set filter
- Cardinality
- Cartesian product
- BOOLEAN and integer interval as sets
- function set
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
- [] (always)
- <> (eventually)
- WF_v(A) (weak fairness)
- fairness conjunct on Spec
- Invariant (as a TLA+ operator, checked at every state)
- PROPERTY (TLC model config: register a temporal property)
