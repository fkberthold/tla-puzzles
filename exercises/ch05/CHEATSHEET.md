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
  Syntax shape: `X <- [model value]`
  Section anchor: `constants#model_value`

- Construct: set of model values
  Syntax shape: `S <- [model value] {s1, s2, s3}`
  Section anchor: `constants#model_set`

- Construct: symmetry set
  Syntax shape: mark a model-value set "symmetry" in the constant assignment dialog
  Section anchor: `constants#symmetry_set`

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
