# USES: pluscal/07-peterson

Subject: Peterson's mutual-exclusion algorithm in raw TLA+ with a
hand-rolled program counter, where each side raises a flag and then hands
the turn away, so whoever gave it last is the one that stands back.

rc: 0

## What the properties rest on

rc 0 over 26 distinct states, 46 generated, depth 7, with deadlock
checking on. Twenty-six is small because `flag` isn't free. A process
holds its flag raised from `set` through `exit` and nowhere else, so
`flag` is a function of `pc`. The 200 combinations the three variables'
domains allow collapse to 50, and 26 of those are reached.

`Enter`'s guard is a disjunction, and each disjunct answers a different
state. `~flag[Other(p)]` fires when nobody else wants in. `turn = p` is
the tie-break for when both do. Drop either one and `MutEx` still holds,
so safety isn't what the disjunction is for.

- The `turn = p` disjunct dropped gives rc 11, a deadlock.
- The same module under `CHECK_DEADLOCK FALSE` gives rc 13 on `Waiting`.
- The `~flag[Other(p)]` disjunct dropped gives rc 13 on `Waiting`.
- The `flag` and `turn` writes swapped gives rc 13 on `TurnIsGiven`.
- The same swap, with both properties out of the config, gives rc 12.
- `WF_vars(Drop(p))` removed gives rc 13.

Without `turn = p`, both sides raise a flag and then neither guard can
ever be true again. Without `~flag[Other(p)]` the counterexample is three
steps long. `p1` raises its flag, hands the turn to `p2`, and then waits
forever, because `p2` never leaves `ncs`. Swapping the two writes is the
safety bug, over a seven-state trace. Both sides name the other before
either raises a flag. `p2` then walks in on a flag still down, and `p1`
walks in on a turn already its own. The last row is the mildest of the
six: a process that stops at `exit` keeps its flag raised, and the other
side's guard wants it down.

`Fairness` names four of the five actions, and `Raise` is the one left
out. That's what makes the third row fail rather than merely run slow. A
process may sit in `ncs` forever, so `Waiting` asks nothing of a process
that never wants in and everything of one that does.
`\A p \in Proc : []<>(pc[p] = "cs")` is the property this model can't
carry. Measured, it gives rc 13 against the spec as it stands. A process
that stays in `ncs` refutes it, and nothing here promises it'll move.

Weak fairness is enough for `Waiting`, and I think that's the comparison
worth making against `pluscal/03-contend`. There a process on the same
shape of guard starves under `fair` and needs `fair+`. A blocked `p`
writes neither `flag` nor `turn`, so the other side is the only thing
that can move. The move that unblocks `p` is `Yield`, which hands `p` the
turn and blocks the other side in the same step. From there the guard
stays true, which is the hypothesis weak fairness needs and the one
`03-contend`'s `await ~lock` never gets.

`TurnIsGiven` is the same mechanism as an action property. A step that
sets `turn` to `p` is a step the other process took from `set`. So you
can't hand yourself the turn, and that's why the last writer waits.

Three states worth knowing are reached. For each one an invariant that
denies it comes back rc 12: one process inside while the other waits,
both at `wait` at once, and a `wait` whose guard is false in that state.
So neither `MutEx` nor `Waiting` is quiet about an empty set of
behaviors.

## Constructs

- Trans helper action for pc transitions
- pc (PlusCal's label-tracking variable)
- pc[...] (multi-process pc)
- label-as-action encoding

`ProcSet` isn't claimed. The process set is the `Proc` constant the
config supplies, so the name a translation would generate never appears.

## Constructs from other families, also exercised

- Operator definition
- EXTENDS (module import)
- Equality and inequality
- Strings
- Booleans and logical operators
- Bullet-point boolean notation
- Implication
- Sets
- Set relational and algebraic operators
- Cardinality
- BOOLEAN and integer interval as sets
- CHOOSE
- Invariant (as a TLA+ operator, checked at every state)
- \A (universal quantifier, "forall")
- \E (existential quantifier, "exists")
- CONSTANT
- ASSUME
- set of model values
- function literal
- function set
- deadlock (checking)
- [] (always)
- PROPERTY (TLC model config: register a temporal property)
- ~> (leads-to)
- action property
- ' (prime, next-state value)
- [P]_x (box action formula)
- VARIABLE / VARIABLES
- vars (the all-variables tuple)
- Init / Next / Spec (the pure-TLA+ spec skeleton)
- action (formal definition)
- UNCHANGED
- nondeterministic action (\E form and disjunction form)
- EXCEPT
- WF_v(A) (weak fairness)
- fairness conjunct on Spec
- fairness on a subaction
