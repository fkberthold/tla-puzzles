# USES: core/03-cups

Subject: Five cups in a row, all face down. The only move turns over two
cups with one cup between them, and the odd and even places never mix.

rc: 0

## What the properties rest on

Both parity invariants rest on the gap being two rather than one.
Turning over neighbors instead gives rc 12 against `OddPlaces`, and
rc 12 against `NoMixedPair`, measured as two separate runs.

`EvenAmong` is one law and the .cfg names its two instances separately,
which is what `.claude/rules/tla-practice.md` section 1 asks for. Eight
of the thirty-two cup positions are reachable.

## Constructs

- Operator definition
- Equality and inequality
- Integers
- Booleans and logical operators
- Implication
- LET-IN
- \A (universal quantifier, "forall")
- \E (existential quantifier, "exists")
- Higher-order operator parameter
- LAMBDA

## Constructs from other families, also exercised

- EXTENDS (module import)
- Sets
- Set relational and algebraic operators
- Set filter
- Cardinality
- BOOLEAN and integer interval as sets
- VARIABLE / VARIABLES
- vars (the all-variables tuple)
- Init / Next / Spec (the pure-TLA+ spec skeleton)
- action (formal definition)
- nondeterministic action (\E form and disjunction form)
- ' (prime, next-state value)
- [P]_x (box action formula)
- Invariant (as a TLA+ operator, checked at every state)
