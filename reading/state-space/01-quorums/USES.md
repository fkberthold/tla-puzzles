# USES: state-space/01-quorums

Subject: Four processes each cast one vote, and any majority of them can
record an outcome. Outcomes accumulate in a set and are never removed.

rc: 0

## What the properties rest on

rc 0 over 99 distinct states, 285 generated, depth 6.

`Agreement` rests on a quorum being a strict majority. Relax `Quorum` to
`2 * Cardinality(q) >= Cardinality(Proc)` and the run gives rc 12 with
`Agreement` named: two disjoint sets of two then both qualify, and the
four processes can split two against two.

`Justified` rests on Decide's guard rather than on anything in the
invariant. Delete the `\E q \in Quorum : \A p \in q : vote[p] = v`
conjunct and the run gives rc 12 with `Justified` named.

`Settled` turns out not to be measuring what the `\cup` suggests, and
that is the result worth sitting with. Replace `outcomes' = outcomes
\cup {v}` with `outcomes' = {v}` and the run still gives rc 0. A strict
majority of four cannot be mustered twice for different values, so
`outcomes` never holds a value that an assignment would drop. The
monotone update is what makes the module say what it means, and here
measurement cannot tell it from the destructive one.

## Constructs

- SUBSET (powerset)
- Set filter
- Cardinality
- set of model values
- Invariant (as a TLA+ operator, checked at every state)
- deadlock (checking)

## Constructs from other families, also exercised

- Operator definition
- EXTENDS (module import)
- Integers
- Strings
- Equality and inequality
- Bullet-point boolean notation
- Set relational and algebraic operators
- function set
- function literal
- EXCEPT
- \A (universal quantifier, "forall")
- \E (existential quantifier, "exists")
- CONSTANT
- VARIABLE / VARIABLES
- vars (the all-variables tuple)
- Init / Next / Spec (the pure-TLA+ spec skeleton)
- action (formal definition)
- nondeterministic action (\E form and disjunction form)
- ' (prime, next-state value)
- [P]_x (box action formula)
- action property
- UNCHANGED
- PROPERTY (TLC model config: register a temporal property)
