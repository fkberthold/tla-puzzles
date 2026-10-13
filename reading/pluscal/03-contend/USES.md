# USES: pluscal/03-contend

Subject: Two processes run the same three statements against one lock, and
the only difference between them is `fair` against `fair+`.

rc: 0

Translated with `pcal -lineWidth 72 -nocfg`. The translation is committed,
so the module checks as it stands.

## Measured probes

`KeenEnters` and `SlowEnters` are the same formula over a different process.
The config names one of them, and which one is not arbitrary.

- `PROPERTY SlowEnters` added gives rc 13.
- `fair+` downgraded to `fair` on `keen` gives rc 13.

The weakly fair process can starve because its guard is never continuously
true. Each time the other side takes the lock, `await ~lock` goes false,
and weak fairness asks for nothing when that happens.

`CHECK_DEADLOCK TRUE` is deliberate. There's no `Terminating` disjunct to
absorb the end of a run, so the check is live, and a state with neither
process able to move would be a state `Held` already rules out.

The loop is a `while (TRUE)` rather than a `goto`. That's a line-budget
choice, not a reading one. With `goto` pcal emits a `Terminating` disjunct
that nothing here can reach, and those seven lines took the module to 67.
No `goto` is reached by any of the five models for the same reason.

## Constructs

- --algorithm block
- := assignment
- label
- label-as-action encoding
- while
- await
- process (single)
- pc (PlusCal's label-tracking variable)
- pc[...] (multi-process pc)
- ProcSet
- fair process (weak fairness)
- fair+ (strong fairness)

## Constructs from other families, also exercised

- Operator definition
- Equality and inequality
- Booleans and logical operators
- Bullet-point boolean notation
- Strings
- Sets
- Set relational and algebraic operators
- BOOLEAN and integer interval as sets
- CASE
- function literal
- function set
- EXCEPT
- VARIABLE / VARIABLES
- vars (the all-variables tuple)
- Init / Next / Spec (the pure-TLA+ spec skeleton)
- action (formal definition)
- nondeterministic action (\E form and disjunction form)
- ' (prime, next-state value)
- [P]_x (box action formula)
- [] (always)
- []<> (always eventually)
- WF_v(A) (weak fairness)
- SF_v(A) (strong fairness)
- fairness conjunct on Spec
- fairness on a subaction
- Invariant (as a TLA+ operator, checked at every state)
- PROPERTY (TLC model config: register a temporal property)
- deadlock (checking)
