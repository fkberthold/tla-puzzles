# USES: pluscal/01-euclid

Subject: Repeated subtraction on a pair of numbers, with the common
divisors of the pair named as an operator and watched at every state.

rc: 0

Translated with `pcal -lineWidth 60 -nocfg -termination`. The
translation is committed, so the module checks as it stands.

That `-termination` is where the `WF_vars(Next)` on line 43 comes from. The
algorithm block carries no `fair` and no `process`, so the flag supplies the
fairness on its own. Measured three ways by the `tla-fwkz.2.1` author: a
`fair process` with no flag gives `WF_vars`, no keyword with `-termination`
gives `WF_vars` anyway, and a `fair process` with `-nof` gives nothing. Read
`reading/pluscal/02-interleave` for the keyword itself.

## Constructs

- --algorithm block
- label
- while
- PlusCal if
- := assignment
- pc (PlusCal's label-tracking variable)
- Terminating
- label-as-action encoding

## Constructs from other families, also exercised

- Operator definition
- IF-THEN-ELSE
- Integers
- Set filter
- Set relational and algebraic operators
- Equality and inequality
- Implication
- Bullet-point boolean notation
- \A (universal quantifier, "forall")
- CONSTANT
- ASSUME
- BOOLEAN and integer interval as sets
- VARIABLE / VARIABLES
- vars (the all-variables tuple)
- Init / Next / Spec (the pure-TLA+ spec skeleton)
- ' (prime, next-state value)
- [P]_x (box action formula)
- UNCHANGED
- <> (eventually)
- fairness conjunct on Spec
- Invariant (as a TLA+ operator, checked at every state)
- PROPERTY (TLC model config: register a temporal property)
