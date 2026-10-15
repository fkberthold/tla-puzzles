# USES: modules/04-cycle

Subject: A washer stepping through fill, wash and spin on a countdown timer,
refining an abstraction that cannot see the timer and still demands progress.

rc: 0

## What the properties rest on

Dwell = 2 gives rc 0 over 9 distinct states, 13 generated, depth 7. Nine is
three phases against three timer values, so the search is complete. The count
runs 3 * (Dwell + 1), measured at 6 for Dwell = 1 and 12 for Dwell = 3.

`WF_vars(Tick)` is the conjunct to sit with. `Tick` never touches `phase`, so
every `Tick` step is a stuttering step of `Ring`, and `Ring` is where the only
liveness claim in the file lives. Nothing in the outer module asks for a timer
that runs down, so I read that conjunct as decoration the first time through.
Drop it and the run gives rc 13.

What asks for it is `WF_ph(RNext)`, the third conjunct of `RSpec`. It wants a
phase change infinitely often, and `Advance` sits disabled until the timer
reaches 0, so ticking is the only route to the next phase. The two action
properties are the halves of that argument stated on their own.
`TickInvisible` says `Tick` leaves the phase alone, and `WaitsForZero` says the
phase moves only at 0.

Delete `WF_ph(RNext)` from `RSpec` and the outer `Spec` can shed its whole
`Fairness` conjunct at rc 0. So every bit of liveness this model has to earn is
written inside the submodule, and refining a fair spec is a liveness obligation
and not only a safety one.

Eight probes, seven of them rc 13, and the name TLC prints moves around.

| the edit | what TLC prints |
|---|---|
| `WF_vars(Tick)` dropped | `Temporal property Refines was violated` |
| `WF_vars(Advance)` dropped | the same |
| `Fairness` dropped from `Spec` | the same |
| `Advance` reads `Order[Order[phase]]` | `Action property line 9, col 19 to line 9, col 30` |
| `Tick` made to move the phase | `Action property TickInvisible is violated` |
| `Advance` guarded by `timer >= 0` | `Action property WaitsForZero is violated` |
| `Init` started at `"wash"` | `Property RInit is violated by the initial state` |
| `Dwell = 0` in the .cfg | rc 10, `Assumption line 13 ... is false` |

Line 9 is `RSpec` and columns 19 to 30 are `[][RNext]_ph`. So the fairness half
answers to the name the .cfg declared and the box-action half to its own source
span, and one property reports under two names depending on which conjunct
broke. The initial-state row is the one I would not have predicted. A
`PROPERTY` refuted by the very first state still comes back rc 13 rather than
12.

The root ASSUME earns its keep rather than tidying up after itself. At
Dwell = 0 the reset `timer' \in 1..Dwell` ranges over the empty set, so nothing
could ever advance and the liveness obligation would fail on a model nobody
meant to write.

## Constructs

- EXTENDS (module import)
- INSTANCE
- named instance
- ! (namespace lookup)
- INSTANCE ... WITH (<- constant substitution)

Every parameter of `Ring` is named in the `WITH` clause, so `partial
parameterization` is not claimed here. `modules/02-gears` is the item that
leaves one out.

## Constructs from other families, also exercised

- Operator definition
- Integers
- Strings
- Equality and inequality
- Implication
- Bullet-point boolean notation
- CASE
- Sets
- BOOLEAN and integer interval as sets
- function literal
- CONSTANT
- ASSUME
- VARIABLE / VARIABLES
- vars (the all-variables tuple)
- Init / Next / Spec (the pure-TLA+ spec skeleton)
- action (formal definition)
- nondeterministic action (\E form and disjunction form)
- ' (prime, next-state value)
- [P]_x (box action formula)
- UNCHANGED
- action property
- WF_v(A) (weak fairness)
- fairness conjunct on Spec
- fairness on a subaction
- Invariant (as a TLA+ operator, checked at every state)
- PROPERTY (TLC model config: register a temporal property)
