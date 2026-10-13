# USES: functions-records/03-overlay

Subject: A stack of config layers merged into one function, where the
layer on top wins every key it binds.

rc: 0

`@@` keeps the left operand's value on a shared key, so the fold in
`Flat` has to put the higher layer on the left. `Topmost` is what that
buys, and I think it's the one worth the time. The effective value of a
key comes from the highest live layer that binds it, and the only reason
is the order of two arguments.

`Covered` is the quieter half. The domain is the union of every live
layer, even though the value comes from one of them.

## What the properties rest on

Two variants, each one change away from the module above.

| change | rc |
|---|---|
| `Flat`'s two `@@` operands swapped, so the lower layer wins | 12 |
| Pop no longer blanks the layer it leaves behind | 13 |

The second is why `PushChangesNothing` is in the config. Without the
blanking, a Push brings a popped layer's old bindings back, and the rc
moves to 13 because TLC checks a boxed action through the implied-action
channel.

## Constructs

- DOMAIN
- function literal
- function set
- :> (singleton function)
- @@ (function merge)
- Bracket function definition
- Recursive function definition
- EXCEPT
- @ (the original value, inside EXCEPT)

`UNION` is here twice and has no row in `drill/INVENTORY.md`, so it
isn't claimed below.

## Constructs from other families, also exercised

- Operator definition
- IF-THEN-ELSE
- Integers
- Equality and inequality
- Implication
- Bullet-point boolean notation
- \A (universal quantifier, "forall")
- \E (existential quantifier, "exists")
- Sets
- Set relational and algebraic operators
- Set map
- SUBSET (powerset)
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
- action property
- UNCHANGED
- Invariant (as a TLA+ operator, checked at every state)
- PROPERTY (TLC model config: register a temporal property)
