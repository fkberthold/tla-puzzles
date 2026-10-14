# USES: modules/01-bitcounter

Subject: Two bits and a display, checked against a submodule that counts
0 to 3 and back, through a refinement mapping.

rc: 0

## What the properties rest on

rc 0 over 16 distinct states, 33 generated, depth 8. Sixteen is every
pair of bits against every display value, so the search is complete.

`Refines` rests on `Value` counting 0, 1, 2, 3 in that order. Three
changes break it and all three give rc 13.

- `Tick`'s `hi' = IF lo THEN ~hi ELSE hi` flattened to `hi' = ~hi`.
- The submodule's `(n + 1) % 4` narrowed to `% 3`.
- `Refresh` made to flip `lo` as well as write `shown`.

The third is the one to sit with. `Refresh` changes `shown` and leaves
`Value` alone, so it maps to a stuttering step of the abstract module,
which `[][MFNext]_n` admits. Give it any effect on `lo` or `hi` and it
stops being stuttering and has to be a real `MFNext` step instead.

What TLC names is worth reading too. It reports not `Refines` but
`Action property line 11, col 21 to line 11, col 32 of module
BitCounter`, which is the `[][MFNext]_n` inside `ModFour`. The
obligation TLC checks is the submodule's box action after substitution,
and the name in the config is only how it got there.

## Constructs

- EXTENDS (module import)
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
