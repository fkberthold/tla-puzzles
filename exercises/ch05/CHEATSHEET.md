# Chapter 05 cheat sheet: Parameterizing Specs

## Header

- Chapter number: `05`
- Chapter title: `Parameterizing Specs`
- learntla-v2 clone SHA: `09840bfc2ee9a88cdbedb672be77a6c73942fe16`

## Constructs introduced

- Construct: `CONSTANT`
  Syntax shape: `CONSTANT S` or `CONSTANT S, Length`
  Section anchor: `constants#constant`

- Construct: `ASSUME`
  Syntax shape: `ASSUME S # {}`
  Section anchor: `constants#ASSUME`

- Construct: model value
  Syntax shape: `CONSTANT Unclaimed = Unclaimed` in the `.cfg`. A bare word on
  the right of the `=`, no quotes and no digits, is a model value.
  Toolbox equivalent: `X <- [model value]` in the constant assignment dialog.
  Section anchor: `constants#model_value`

- Construct: set of model values
  Syntax shape: `CONSTANT Runners = {r1, r2, r3}` in the `.cfg`. Bare words
  again, one per element.
  Toolbox equivalent: `S <- [model value] {s1, s2, s3}`.
  Section anchor: `constants#model_set`

- Construct: symmetry set
  Syntax shape: `Perms == Permutations(Runners)` in the module, then
  `SYMMETRY Perms` in the `.cfg`. The module names the permutation set and the
  `.cfg` points at it.
  Toolbox equivalent: mark a model-value set "symmetry" in the constant
  assignment dialog.
  Section anchor: `constants#symmetry_set`

- Trap: a `.cfg` assigns a literal, never an expression. `CONSTANT N = 3`
  works. `CONSTANT N = -1` and `CONSTANT N = 0 - 1` are both config syntax
  errors. The toolbox takes an expression because it writes a generated module
  for you. The `.cfg` route has nowhere to put one.

## Major themes

- `Constants defer concrete values to the model run, keeping the spec free of hardcoded settings.`
- `ASSUME documents and enforces valid constant values before a run starts.`
- `Model values give an opaque, self-only-equal type for sentinels and placeholders.`
- `Symmetry sets collapse states that only differ by relabeling model values.`
- `Constants can also steer a spec's behavior, not just supply data, like a DEBUG flag.`

## Boundary notes

What this chapter does NOT cover, because a neighbouring chapter does.

- `Length` as a `CONSTANT` for controlling sequence length is covered in chapter `06` instead.
- Writing invariants (define blocks, quantifiers, `=>`) is covered in chapter `04` instead.
- Symmetry sets' payoff for concurrent systems is covered in `topics/optimization.rst` instead, outside `core`. Chapter `09` covers the one `core` follow-up, that symmetry sets can't be used with liveness properties.
