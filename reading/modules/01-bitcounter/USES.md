# USES: modules/01-bitcounter

Subject: Two bits and a display, checked against a submodule that counts
0 to 3 and back, through a refinement mapping.

rc: 0

## Constructs

- INSTANCE
- named instance
- ! (namespace lookup)
- PROPERTY (TLC model config: register a temporal property)

`INSTANCE ... WITH` is here with a VARIABLE on the left, not a constant,
so `drill/INVENTORY.md`'s row for it is deliberately not claimed.

## Constructs from other families, also exercised

- Operator definition
- IF-THEN-ELSE
- Integers
- Booleans and logical operators
- Bullet-point boolean notation
- Equality and inequality
- BOOLEAN and integer interval as sets
- VARIABLE / VARIABLES
- vars (the all-variables tuple)
- Init / Next / Spec (the pure-TLA+ spec skeleton)
- action (formal definition)
- nondeterministic action (\E form and disjunction form)
- ' (prime, next-state value)
- [P]_x (box action formula)
- UNCHANGED
- Invariant (as a TLA+ operator, checked at every state)
