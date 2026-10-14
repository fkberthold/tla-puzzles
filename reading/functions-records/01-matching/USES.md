# USES: functions-records/01-matching

Subject: A function on a set of nodes, where the only moves pair two
unpaired nodes or unpair a pair.

rc: 0

## What the properties rest on

rc 0 over 10 distinct states, 49 generated, depth 3. Ten is every
involution on a four-element set, so the run reaches all of them.

`Involution` rests on both ends of a move being written together. Cut
Pair's EXCEPT down to `[mate EXCEPT ![a] = b]` and the run gives rc 12
with `Involution` named, because `a` then points at `b` while `b` still
points at itself.

`EvenlyPaired` has slack in it rather than being tight. Tighten the
bound to `Cardinality({n \in Node : mate[n] # n}) <= 2` and the run
gives rc 12, so two disjoint pairs really are reached.

One guard turns out to be redundant, and that result is worth more than
the two above. Delete `mate[b] = a` from Unpair and the run still gives
rc 0. `Involution` already holds in every reachable state, so
`mate[a] = b` implies the conjunct that was dropped. The guard stays
because it says what an Unpair is, not because a probe caught it.

## Constructs

- function set
- function literal
- EXCEPT
- Set filter
- Cardinality

## Constructs from other families, also exercised

- Operator definition
- EXTENDS (module import)
- Integers
- Equality and inequality
- Bullet-point boolean notation
- \A (universal quantifier, "forall")
- \E (existential quantifier, "exists")
- CONSTANT
- set of model values
- VARIABLE / VARIABLES
- vars (the all-variables tuple)
- Init / Next / Spec (the pure-TLA+ spec skeleton)
- action (formal definition)
- nondeterministic action (\E form and disjunction form)
- ' (prime, next-state value)
- [P]_x (box action formula)
- Invariant (as a TLA+ operator, checked at every state)
