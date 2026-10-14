# USES: pluscal/04-ring

Subject: A ring buffer of four slots with a head index, a tail index and a
count. The two indices are equal in two different situations.

rc: 0

## What the properties rest on

Translated with `pcal -lineWidth 72 -nocfg`. The translation is committed,
so the module checks as it stands.

`pc` is absent. One label inside `while (TRUE)` leaves pcal nothing to
track, so it drops the variable and writes `Next` as a bare disjunction.

`Ambiguous` is the one to sit with. `head = tail` holds when the buffer is
empty and again when it's full, so the two indices on their own can't tell
those apart. That's why `count` is carried at all.

- `Ambiguous` weakened to `count = 0` gives rc 12.
- The `await count < Cap` guard dropped gives rc 12.

`Gap` is where the ambiguity comes from. The index distance equals the
count mod `Cap`, and 0 and `Cap` are the same residue.

## Constructs

- --algorithm block
- := assignment
- label
- while
- either-or
- await
- macro

## Constructs from other families, also exercised

- Operator definition
- EXTENDS (module import)
- Integers
- Equality and inequality
- Implication
- Booleans and logical operators
- Bullet-point boolean notation
- Sets
- BOOLEAN and integer interval as sets
- CONSTANT
- ASSUME
- VARIABLE / VARIABLES
- vars (the all-variables tuple)
- Init / Next / Spec (the pure-TLA+ spec skeleton)
- action (formal definition)
- nondeterministic action (\E form and disjunction form)
- ' (prime, next-state value)
- [P]_x (box action formula)
- action property
- [] (always)
- Invariant (as a TLA+ operator, checked at every state)
- PROPERTY (TLC model config: register a temporal property)
