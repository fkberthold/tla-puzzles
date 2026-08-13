# Chapter 07 cheat sheet: Nondeterminism

## Header

- Chapter number: `07`
- Chapter title: `Nondeterminism`
- learntla-v2 clone SHA: `09840bfc2ee9a88cdbedb672be77a6c73942fe16`

## Constructs introduced

- Construct: nondeterministic `with`
  Syntax shape: `with x \in set do ... end with;` tries every value in `set`
  Section anchor: `nondeterminism#nondet_with`

- Construct: `either-or`
  Syntax shape: `either branch1 or branch2 or branch3 end either;` picks one branch
  Section anchor: `nondeterminism#either`

## Major themes

- Nondeterminism breaks the pattern of every earlier spec, where each starting state had one fixed behavior. Randomness, user input, sensor readings, and independent moving parts (concurrency, deferred to the next chapter) all need more than one possible next step.
- `with x \in set` and `either-or` are the two PlusCal constructs for this. `with` picks a value, `either` picks a branch, and both can nest inside each other or combine with the deterministic forms from earlier chapters.
- Nondeterminism is an abstraction tool, not just a modeling need. The `either or skip` pattern lets a spec say "this step succeeds, or something went wrong" without spelling out every failure cause, and you can add back as much error detail as actually matters.
- The same idea models outside actions. Instead of hand-picking one request to test, `with request \in RequestType` pulls any possible request from a defined type, covering every case at once.
- The calculator example escalates a single deterministic digit-adder into a nondeterministic choice of add, subtract, or multiply, then flips the usual pattern by writing an invariant that is false at the target sum. TLC's counterexample trace becomes a search result, a path that reaches the target.
- More nondeterminism means a bigger state space. The chapter tracks this directly, comparing seen-to-distinct-state ratios before and after adding the operator choice, as part of why nondeterministic specs are harder to reason about.

## Boundary notes

- Concurrency, the last of the four nondeterminism sources this chapter lists (independent parts running in unknown order), is covered in chapter `08` instead.
- Deadlock, which an empty nondeterministic `with` set can cause by blocking forever, is covered in chapter `08` instead.
- `await`, PlusCal's general blocking-until-condition construct, is covered in chapter `08` instead.
- Struct set syntax, already in use in the `RequestType == [from: Client, type: {...}, params: ParamType]` example, is defined in chapter `06` instead.
