# Cheat sheet: learntla core ch.4

## Header

- Chapter number: `04`
- Chapter title: `Writing an Invariant`
- learntla-v2 clone SHA: `09840bfc2ee9a88cdbedb672be77a6c73942fe16`

## Constructs introduced

- Construct: `Invariant` (as a TLA+ operator, checked at every state)
  Syntax shape: `TypeInvariant == /\ var \in Set`
  Section anchor: `invariants#invariant`

- Construct: `define` block (PlusCal)
  Syntax shape: `define ... end define;`
  Section anchor: `invariants#define`

- Construct: `pc` (PlusCal's label-tracking variable)
  Syntax shape: `pc = "LabelName"`
  Section anchor: `invariants#pc`

- Construct: `\A` (universal quantifier, "forall")
  Syntax shape: `\A x \in S: P(x)`
  Section anchor: `invariants#\A`

- Construct: `\E` (existential quantifier, "exists")
  Syntax shape: `\E x \in S: P(x)`
  Section anchor: `invariants#\E`

## Major themes

- An invariant is a property TLC checks on every reachable state, not just whether the spec runs without error.
- Type invariants use `\in` and `\subseteq` to pin down the shape of each variable.
- The error trace shows one state per row, with `pc` marking the current label and changed values in red.
- `pc` and `=>` together restrict a check to a specific point, like "only when `pc = \"Done\"`".
- `\A` and `\E` are vacuous on the empty set: `\A` is always true there, `\E` is always false.
- `=>` inside a quantifier rules out unwanted combinations, but pairing `=>` with `\E` instead of `/\` makes the check trivially true.

## Boundary notes

- `Registering an invariant with TLC (the toolbox's "Invariants" box)` is covered in chapter `01` instead.
- `The => (implies) operator itself, including its precedence rules` is covered in chapter `02` instead.
- `CHOOSE and LET...IN, used here to inspect a failing quantifier` is covered in chapter `02` instead.
- `assert, and how its error trace differs from an invariant's` is covered in chapter `03` instead.
- `Making S a configurable model constant instead of a fixed operator` is covered in chapter `05` instead.
