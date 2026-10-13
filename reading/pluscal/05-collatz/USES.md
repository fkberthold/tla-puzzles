# USES: pluscal/05-collatz

Subject: Halve it if it's even, else triple it and add one, until it hits
1. The call goes through a procedure, so the generated stack is on show.

rc: 0

Translated with `pcal -lineWidth 72 -nocfg`. The translation is committed,
so the module checks as it stands.

## Measured probes

`Peak` says the run never goes above 52, starting from 7. The bound is
tight, which is not what the first few steps suggest.

- `Peak` tightened to `n <= 51` gives rc 12.
- `assert n > 1` tightened to `n > 2` gives rc 14.

rc 14 is its own verdict row, separate from an invariant violation. An
`assert` fires during exploration at the control point it sits on, which
is a different thing from an invariant checked at every state.

`Depth` is the one to sit with. The procedure is called from a loop and
never from itself, so one frame is all the stack ever holds, and that
frame's `pc` field is the return address as a data value.

`Termination` holds here and the general statement is an open problem. The
property is about N = 7 and nothing more.

There's no `TypeOK`, and that's the 60-line bound rather than a choice. A
procedure's translation runs 42 lines on its own, which leaves 18 for the
preamble, the algorithm and the properties together. `01-euclid` has no
`TypeOK` either.

## Constructs

- --algorithm block
- := assignment
- label
- label-as-action encoding
- while
- PlusCal if
- assert
- procedure
- call
- return
- pc (PlusCal's label-tracking variable)
- Terminating

The fairness comes from `--fair algorithm`, which has no inventory row of
its own. `fair process` is not claimed, because there's no process here.

## Constructs from other families, also exercised

- Operator definition
- EXTENDS (module import)
- IF-THEN-ELSE
- Integers
- Strings
- Equality and inequality
- Bullet-point boolean notation
- Sequences
- Sequence module operators
- struct literal
- CONSTANT
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
- Invariant (as a TLA+ operator, checked at every state)
- PROPERTY (TLC model config: register a temporal property)
