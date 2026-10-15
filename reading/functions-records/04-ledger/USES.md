# USES: functions-records/04-ledger

Subject: A count of hits per key, kept two ways at once. One function
carries a value for every key, the other carries only the keys it has
seen, and a key can be forgotten.

rc: 0

## What the properties rest on

rc 0 over 64 distinct states, 289 generated, depth 10. Sixty-four is
every function from three keys into `0..3`, so the run reaches all of
them. Once the two invariants hold, `sparse` carries no freedom of its
own.

A function has no delete. `@@` widens a domain and `EXCEPT` changes a
value inside one, and between them that's everything the language
offers. So `Hit` gets to pick one of the two, and `Forget` has to write
the function out again over a smaller domain. I think that asymmetry is
what's worth the time here. `Forget` is the only action in the module
that `EXCEPT` can't express.

`Agree` is one equality because `Total` reads the sparse map as a total
function first. `Logged` is the half that watches a domain, and it's the
one the first probe below breaks.

Four variants, each one change away from the module above.

| change | rc |
|---|---|
| `Forget` zeroes the value with `EXCEPT` instead of rebuilding | 12, `Logged` |
| `Hit` always uses `EXCEPT`, dropping the merge branch | 12, `Agree` |
| `Hit` always merges, dropping the `EXCEPT` branch | 12, `Agree` |
| the merge operands swapped, `(k :> 1) @@ sparse` | 0 |

The second row is the one I'd stop on. `EXCEPT` on a key the function
doesn't carry is a no-op rather than an error, and the `@` inside it
never gets evaluated. So `sparse` stays empty while `tally` climbs. TLC
prints that state as `sparse = <<>>` and names `Agree` at depth 2. A
mistake about a domain is silent here, which is why `Hit` branches on
`DOMAIN sparse` instead of leaving `EXCEPT` to cope.

The last row comes back green, and that's a fact about the operands
rather than about `@@`. The merge only ever runs on a key the map
doesn't carry, so nothing overlaps and the order can't matter. Put the
merge in the other branch and the order would decide everything.

One more green result, and it's the one I didn't expect. Delete
`Forget(k)` from `Next` and the run still finds all 64 states, 145
generated instead of 289. Every state `Forget` reaches, `Hit` already
reached by a shorter path. So `Forget` buys no coverage at all, and the
module still needs it. It's the only action that shrinks a domain, and
both interesting invariants are about domains.

## Constructs

- DOMAIN
- function literal
- function set
- :> (singleton function)
- @@ (function merge)
- EXCEPT
- @ (the original value, inside EXCEPT)

`:>` and `@@` come from the `TLC` standard module rather than from
`Naturals`, which is why the `EXTENDS` line names it.

## Constructs from other families, also exercised

- Operator definition
- EXTENDS (module import)
- IF-THEN-ELSE
- Integers
- Equality and inequality
- Booleans and logical operators
- Bullet-point boolean notation
- \A (universal quantifier, "forall")
- \E (existential quantifier, "exists")
- Sets
- Set relational and algebraic operators
- Set filter
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
