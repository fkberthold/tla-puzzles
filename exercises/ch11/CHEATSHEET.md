# Chapter 11 cheat sheet: Action Properties

## Header

- Chapter number: `11`
- Chapter title: `Action Properties`
- learntla-v2 clone SHA: `09840bfc2ee9a88cdbedb672be77a6c73942fe16`

## Constructs introduced

- Construct: `action property`
  Syntax shape: `Name == [][action]_vars`, checked with `PROPERTY Name` in the model, never `INVARIANT`
  Section anchor: `action-properties#action_property`

- Construct: `'` (prime, next-state value)
  Syntax shape: `x'` is the value of `x` at the end of the current step, the start of the next step
  Section anchor: `action-properties#prime`

- Construct: `[P]_x` (box action formula)
  Syntax shape: `[P]_x` is shorthand for `P \/ UNCHANGED x`
  Section anchor: `action-properties#box_action`

## Major themes

- Action properties restrict how the system is allowed to change between states. They complement invariants, which restrict what a single state may look like on its own.
- `x'` is the value of a variable at the end of a step, the start of the next one. A formula that mixes `x` and `x'` describes a transition, not a single state.
- A bare next-state formula like `x' = x + 1` is always false as a property, because TLA+ can always insert a stutter step where nothing changes. `[P]_x` fixes this by adding `\/ UNCHANGED x`, so the property tolerates stuttering.
- Helper actions let you factor primed-variable logic into named operators, the same way you would factor any other repeated expression, and reuse it inside more than one action property.
- TLC can only check a top-level action property written as `[A]_v`. A quantifier wrapped around the whole `[]` fails to check. Since `[]` commutes with `\A`, a quantified action property moves the quantifier inside the `[]` instead.
- Action properties are optional. The chapter frames them as flexible but secondary, good for expressing transition rules that invariants and liveness properties do not reach.

## Boundary notes

What this chapter does NOT cover, because a neighbouring chapter does.

- `PROPERTY`, the config directive used to check action properties, is covered in chapter `09` instead. This chapter only points the directive at a new class of formula.
- The formal definition of "action" (a boolean formula containing primed variables) is given in chapter `12` instead. This chapter uses the word informally throughout, even in its own title.
- The full `UNCHANGED` syntax, including the multi-variable form `UNCHANGED <<x, y, z>>` and its meaning (`x' = x`), is covered in chapter `12` instead. This chapter uses `UNCHANGED x` as already-familiar shorthand.
