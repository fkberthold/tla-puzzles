# USES: functions-records/02-shelves

Subject: A shelf where every title owns one slot. A title that goes out
keeps that slot under a different field name.

rc: 0

The two record shapes carry different fields, so `DOMAIN book[t]` is
what tells them apart. `Held` rests on that, and the shape test has to
come first: there's no `.to` to read on a shelved record.

I think `SlotsDistinct` is the one worth the time. It holds because no
action ever invents a slot. Lend copies the slot into `home`, Return
copies it back, and Swap exchanges two of them, so the assignment made
at Init is only ever permuted.

## What the invariants rest on

Three variants, each one change away from the module above.

| change | rc |
|---|---|
| Lend's quota guard dropped | 12 |
| Lend records the title number as home, not the live slot | 12 |
| `Held`'s two conjuncts swapped | 75 |

The last one is the hazard rather than a property. A record field that
only some shapes carry kills the run instead of answering, so the guard
is what keeps the set filter evaluable.

## Constructs

- struct literal
- struct set
- DOMAIN
- function literal
- function set
- EXCEPT

## Constructs from other families, also exercised

- Operator definition
- IF-THEN-ELSE
- Integers
- Strings
- Equality and inequality
- Booleans and logical operators
- Implication
- Bullet-point boolean notation
- \A (universal quantifier, "forall")
- \E (existential quantifier, "exists")
- Set relational and algebraic operators
- Set filter
- Cardinality
- BOOLEAN and integer interval as sets
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
- Invariant (as a TLA+ operator, checked at every state)
