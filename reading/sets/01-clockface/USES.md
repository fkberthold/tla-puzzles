# USES: sets/01-clockface

Subject: A clock hand that moves the same number of hours on every tick,
carrying the set of hours it has landed on. The step size is picked once.

rc: 0

141 distinct states, 152 generated, depth 23, under a second.

## Constructs

- Sets
- Set relational and algebraic operators
- Cardinality
- BOOLEAN and integer interval as sets
- Set map
- CHOOSE

## Constructs from other families, also exercised

- Operator definition
- EXTENDS (module import)
- Integers
- Equality and inequality
- Bullet-point boolean notation
- Implication
- \A (universal quantifier, "forall")
- CONSTANT
- ASSUME
- VARIABLE / VARIABLES
- vars (the all-variables tuple)
- Init / Next / Spec (the pure-TLA+ spec skeleton)
- action (formal definition)
- ' (prime, next-state value)
- [P]_x (box action formula)
- UNCHANGED
- Invariant (as a TLA+ operator, checked at every state)

`Next` is one action and `Init` carries the only choice, so this item does
not claim `nondeterministic action (\E form and disjunction form)`.

## What else was measured

Deadlock checking on, with `--check-deadlock` and the keyword absent: rc 0.
`Tick` is enabled in every state, so the .cfg carries no `CHECK_DEADLOCK`
line.

Two conjuncts were dropped to see whether they hold anything up.

- `Closes` without its `seen # {0}` guard: rc 12. The initial state has the
  hand at noon with one hour seen, so the guard is what keeps the claim off
  it.
- `Divides` over `Cardinality(seen)` rather than `Cardinality(Orbit(step))`:
  rc 12. The count that divides 12 is the finished orbit, not the running
  set.

One dropped conjunct came back green, and that result is worth more than the
two above.

Drop the `\A j \in 1..(k - 1)` line from `Period` and the run still gives
rc 0. Without it the CHOOSE has several witnesses and TLA+ says nothing
about which one you get, so `OrderIsSize` should no longer be a theorem. It
passed because TLC handed back the smallest witness in `1..Face` on this
run. I would not read that as a guarantee about CHOOSE. The minimality
conjunct stays because the semantics need it, not because a probe caught
its absence.
