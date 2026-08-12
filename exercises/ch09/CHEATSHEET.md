# Chapter 09 cheat sheet: Temporal Properties

## Header

- Chapter number: `09`
- Chapter title: `Temporal Properties`
- learntla-v2 clone SHA: `09840bfc2ee9a88cdbedb672be77a6c73942fe16`

## Constructs introduced

- Construct: `[] (always)`
  Syntax shape: `[]P` is true when `P` holds in every state of the behavior
  Section anchor: `temporal-logic#always`

- Construct: `PROPERTY` (TLC model config: register a temporal property)
  Syntax shape: add `PROPERTY Safety` to the model, alongside but distinct from `INVARIANT`
  Section anchor: `temporal-logic#always`

- Construct: `fair process` (weak fairness)
  Syntax shape: `fair process Name = ... begin ... end process;`
  Section anchor: `temporal-logic#fairness`

- Construct: `fair+` (strong fairness)
  Syntax shape: `fair+ process Name ...`, or mark one action strongly fair with `Label:+`
  Section anchor: `temporal-logic#fairness`

- Construct: `<> (eventually)`
  Syntax shape: `<>P` is true when `P` holds in at least one state of the behavior
  Section anchor: `temporal-logic#eventually`

- Construct: `<>[] (eventually always)`
  Syntax shape: `<>[]P` means `P` becomes true and then stays true for the rest of the behavior
  Section anchor: `temporal-logic#eventually`

- Construct: `[]<> (always eventually)`
  Syntax shape: `[]<>P` means `P` becomes true infinitely often, though it can go false again in between
  Section anchor: `temporal-logic#eventually`

- Construct: `~> (leads-to)`
  Syntax shape: `P ~> Q` means whenever `P` is true, `Q` becomes true now or in a later state
  Section anchor: `temporal-logic#leads_to`

## Major themes

- Invariants are just one shape of temporal property. `[]P` is what TLC uses under the hood to check an invariant, but `[]` composes with `\/`, `=>`, and quantifiers to state properties no single state can decide by itself, like "some server stays online forever."
- Safety properties say bad things never happen, liveness properties say good things eventually happen. Every invariant is a safety property, but not every safety property is an invariant, since some need the whole behavior to judge, not one state.
- TLA+ behaviors can stutter forever, standing in for a system that crashes at the worst possible time. A stutter step never breaks an invariant, since nothing changes, but it can block a liveness property from ever being satisfied.
- Fairness rules out infinite stuttering for a process. Weak fairness says a process that can always make progress eventually will. Strong fairness covers a process that can only make progress intermittently, like threads competing for a lock.
- `<>`, `<>[]`, `[]<>`, and `~>` build on `[]` to say "eventually," "eventually stays," "happens infinitely often," and "leads to," each a different way of combining the same always/eventually building blocks.
- Liveness checking costs more than safety checking. TLC is slower at it, can't use symmetry sets, can't say which property failed, and produces longer error traces, so liveness models usually run with smaller constants than safety models.

## Boundary notes

- Declaring a PlusCal `process`, including process sets (`process Name \in Set`), is covered in chapter `08` instead. This chapter only adds the `fair` and `fair+` modifiers on top of that existing syntax.
- `await`, used inside this chapter's example actions (`await lock = NULL`), is covered in chapter `08` instead.
- Recursive operators, higher-order operators, binary operators, function operators, and `CASE` are not used or taught here. They are covered in chapter `10` instead.
