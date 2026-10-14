# USES: pluscal/02-interleave

Subject: Three workers each read a shared counter and write back one more
than they read, with the read and the write in separate labels.

rc: 0

## What the properties rest on

Translated with `pcal -lineWidth 72 -nocfg`. The translation is committed,
so the module checks as it stands.

`-termination` is deliberately not passed. It flips pcal's default fairness
to `-wf`, which conjoins weak fairness whatever the algorithm says, and the
`fair` keyword would then carry no weight. The `Terminating` disjunct and
the `Termination` operator come out anyway.

Both bounds on `counter` are tight, and I think that gap is the thing worth
working out.

- `AtLeastOne` strengthened to `counter = 3` gives rc 12.
- The `fair` keyword dropped gives rc 13 on `Termination`.
- Adding `[][counter' >= counter]_vars` gives rc 13 here, rc 0 at two
  workers.

That last one surprised me. The counter can fall, and it takes three
workers to arrange it.

## Constructs

- --algorithm block
- := assignment
- label
- label-as-action encoding
- pc (PlusCal's label-tracking variable)
- pc[...] (multi-process pc)
- process set
- process-local variable
- self
- ProcSet
- fair process (weak fairness)
- Terminating

`self` appears only in the translation. The algorithm text never writes it,
so a reader meets it in the generated code.

## Constructs from other families, also exercised

- Operator definition
- EXTENDS (module import)
- Integers
- Strings
- Equality and inequality
- Implication
- Bullet-point boolean notation
- Sets
- Cardinality
- BOOLEAN and integer interval as sets
- function literal
- function set
- EXCEPT
- \A (universal quantifier, "forall")
- \E (existential quantifier, "exists")
- CONSTANT
- set of model values
- VARIABLE / VARIABLES
- vars (the all-variables tuple)
- Init / Next / Spec (the pure-TLA+ spec skeleton)
- action (formal definition)
- nondeterministic action (\E form and disjunction form)
- ' (prime, next-state value)
- [P]_x (box action formula)
- UNCHANGED
- <> (eventually)
- WF_v(A) (weak fairness)
- fairness conjunct on Spec
- fairness on a subaction
- Invariant (as a TLA+ operator, checked at every state)
- PROPERTY (TLC model config: register a temporal property)
