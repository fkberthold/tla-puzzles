# USES: core/04-stamps

Subject: A postage machine stocked with 3-cent and 5-cent stamps, adding
one stamp at a time. Four amounts can never be paid exactly, and which
four is the part worth working out.

rc: 0

## What the properties rest on

rc 0 over 17 distinct states at `Small = 3`, `Large = 5`, `Max = 20`.

The claim is that the reachable amounts are exactly `Payable`, and that
is two claims needing two different mechanisms.

`NoGap` is the subset direction. No amount TLC reaches lies outside
`Payable`, and TLC checks that on every state. This is the half rc 0
carries.

The superset direction cannot be an invariant. No single state can say
that every amount from 8 is reached, because a state knows only its own
amount. So it is asserted, in the quantified ASSUME at line 26, and the
assertion is weaker than the claim in two ways worth naming.

It is arithmetic rather than behavior. `Representable(n)` says some count
of each stamp adds up to n, and nothing in it mentions `paid`. That
representable means reachable here rests on `Stick` carrying no guard, so
any bag of stamps summing to n is a real path and no partial sum along it
climbs over n and gets pruned. That argument is the reader's. TLC never
saw it.

It also covers `8..Max` and not all of `Payable`. The four payable
amounts below the last gap are checked by eye: 0 is no stamps, 3 and 5
are one each, 6 is two small ones.

So rc 0 says the subset direction holds and says the arithmetic the
superset direction needs is true. It does not say TLC proved the superset
direction. Removing the quantified ASSUME outright leaves rc 0 over the
same 17 states, which is the plainest way to see that the asserted half
carries none of the verdict.

The 17 is a second route to the same place, and it is not an obligation
either. `Payable` has 17 elements at `Max = 20`, and a subset of a finite
set with the same size is that set. So the count closes the gap, but it
is a number on TLC's console, and this project takes verdicts from exit
codes and never from stdout (`V2-PLAN.md` section 5.1).

Four probes, each its own run. `Small = 4` makes the quantified ASSUME
false and returns 10 before the first state, failing at 11. Remove that
ASSUME and make the same change and the run returns 12 against `NoGap`
at `paid = 4`, which is a gap under the old stamps and reachable under
the new ones. `Max = 5` returns 10 from the hygiene ASSUME at line 10.
Remove the hygiene ASSUME as well and `Max = 5` returns 0 over 3 states,
with `8..5` empty and the quantified ASSUME asserting nothing whatever.
That last pair is how I know the quantified ASSUME is satisfied at the
size shipped rather than skipped, and it is why the hygiene line sets a
floor under `Max` instead of only a ceiling.

`TypeOK` is `paid \in Nat` and not `paid \in 0..Max`. The first draft
wrote the bound and returned 12 at `paid = 21`, so TLC checks an
invariant on a state and applies the CONSTRAINT to it afterwards.
`state-space/02-tickets` holds the neighboring fact about deadlock at a
pruned frontier.

## Constructs

- Operator definition
- Equality and inequality
- Integers
- Booleans and logical operators
- Bullet-point boolean notation
- \A (universal quantifier, "forall")
- \E (existential quantifier, "exists")

## Constructs from other families, also exercised

- EXTENDS (module import)
- CONSTANT
- ASSUME
- Sets
- Set relational and algebraic operators
- BOOLEAN and integer interval as sets
- VARIABLE / VARIABLES
- vars (the all-variables tuple)
- Init / Next / Spec (the pure-TLA+ spec skeleton)
- action (formal definition)
- nondeterministic action (\E form and disjunction form)
- ' (prime, next-state value)
- [P]_x (box action formula)
- Invariant (as a TLA+ operator, checked at every state)

`CONSTRAINT` carries this item too and `drill/INVENTORY.md` has no row
for it, so nothing above claims one. `state-space/02-tickets` records the
same absence.
