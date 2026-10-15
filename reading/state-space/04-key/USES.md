# USES: state-space/04-key

Subject: A storeroom with one key on a hook, and a SPECIFICATION line that
starts the run from the invariant rather than from Init.

rc: 0

## What the properties rest on

rc 0 over 4 distinct states, 10 generated, depth 1. The depth is the tell.
`ISpec` opens with `Inv` where `Spec` opens with `Init`, so TLC starts the
run in every state the invariant admits and takes one step from each of
them. All four states it visits are initial states, which is what a depth
of 1 means.

Point the same three invariants at `SPECIFICATION Spec` and the same four
states come back at depth 2. So `Inv` is exactly the reachable set here
rather than a superset of it, and the two runs agree on the count while
disagreeing on the shape.

`MutEx` on its own is where the work is. Drop `Hooked` from `Inv` and the
run returns 12 with `MutEx` named. Its counterexample opens in a state TLC
builds rather than reaches, the key on the hook and `s1` already inside.
One `Take(s2)` from there puts two people in the storeroom. Put that same
`INVARIANT MutEx` under `SPECIFICATION Spec` and the run returns 0. So the
weaker claim is the one that breaks, and it breaks on a question `Spec`
can't ask. `MutEx` holds at every state the storeroom can reach and still
isn't inductive. `Inv` is both.

The state that does the damage has the key on the hook and somebody already
inside, so no search from `Init` will ever find it. Writing a specification
that starts from the invariant is the only way to hand it to TLC, and I
think that's the whole lesson here.

Editing the `.cfg` alone doesn't get you the 12. `INVARIANT MutEx` under
`SPECIFICATION ISpec`, with `Inv` left alone, returns 0, because `ISpec`'s
initial states are still `Inv`'s. The conjunct has to come out of `Inv`
itself.

The `hook` guard on `Take` is a separate claim, and it's what makes the
storeroom correct at all. Delete it and `INVARIANT MutEx` under
`SPECIFICATION Spec` returns 12.

One measurement sits behind the `CHECK_DEADLOCK FALSE` line. Turn checking
on and the dropped-conjunct probe returns 11 instead of 12, because
`TypeOK /\ MutEx` admits an empty storeroom with the key off the hook,
where neither action is enabled. With `Hooked` back in, that run returns 0,
so all four shipped states do have a successor.

## Constructs

- Invariant (as a TLA+ operator, checked at every state)
- CONSTANT
- set of model values
- deadlock (checking)

`SPECIFICATION` carries this item and `drill/INVENTORY.md` has no row for
it. The spec-skeleton row in the next section covers `Spec` and the `ISpec`
sitting beside it, so nothing claims a row for the keyword.

## Constructs from other families, also exercised

- Operator definition
- EXTENDS (module import)
- Integers
- Equality and inequality
- Booleans and logical operators
- Bullet-point boolean notation
- Sets
- Set relational and algebraic operators
- Cardinality
- BOOLEAN and integer interval as sets
- SUBSET (powerset)
- \E (existential quantifier, "exists")
- VARIABLE / VARIABLES
- vars (the all-variables tuple)
- Init / Next / Spec (the pure-TLA+ spec skeleton)
- action (formal definition)
- nondeterministic action (\E form and disjunction form)
- ' (prime, next-state value)
- [P]_x (box action formula)
