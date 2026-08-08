# Custody reference: representation choices

Author-only note for §9.4. I wrote this after the spec went green, from the decisions
I actually faced. The spec is `authoring/custody/reference/Custody.tla`, checked as
`MCCustody.tla` with two cfgs.

## Notation

I took plain TLA+ over PlusCal. The parties act independently and days begin on their
own, which is bare interleaving, and PlusCal buys nothing for it. It also costs: the
translation's `pc` variable sits in the state for no observable reason, and the
obligations are action properties over an interface, which read best against explicit
actions.

## Derived custody over maintained custody

The biggest fork. Either the model maintains a custodian function and rewrites one
entry on acceptance, or it keeps a set of swapped days and derives custody from the
constants. I took the set, `swapped`, with

`Custodian(d) == IF d \in swapped THEN Other(Scheduled(d)) ELSE Scheduled(d)`

Three reasons. The cap (property 7) becomes `Cardinality` of a set the model already
holds. At-most-one-flip (property 3) is near-structural, since days only enter
`swapped` and never leave. And the handoff's custodian field promised that a deriving
model and a maintaining model produce the same interface, so I took the smaller state.
The cost is that `swapped` means nothing without `Scheduled`, but `Scheduled` is
definable from constants alone, so nothing mutable leaks into it.

## Zero as the no-day marker

`today` and each `pending` slot need a "none". I took `NoDay == 0` over a model value.
With 0, "day d has not begun" is `d > today` at every state, the opening included, and
the none-to-1 march step is the same `+1` as every other step. A model-value marker
forces a case split at every comparison. The cost is that 0 must stay out of `Days`,
which `1..H` gives for free.

## Two named parents

`CONSTANTS A, B` with `Other(p) == IF p = A THEN B ELSE A`, over a `Parents` set
constant. The handoff calls two the domain's own number, not a bound, so I saw no
reason to pay for generality the system doesn't have. `Other` over a set needs
`CHOOSE`, which reads worse and checks the same.

## Pending as a total function

`pending \in [Parents -> {NoDay} \cup Days]`, over a set of parent-day pairs. Rule 7's
one-outstanding-per-parent rides the function shape itself, which is where the handoff
says it belongs, and the `Observe.pending` field is then the variable with no
rendering step.

## Voiding is folded into the steps that cause it

Rule 8 says voiding is immediate, so `BeginDay` clears proposals naming the day it
begins, and `Accept` clears every proposal naming the accepted day in the same update.
The alternative, a separate `Void` action, makes voiding eventual, and property 6 is
then false in every state between cause and cleanup. I think this fold is the one
choice a variant author is most likely to unfold, and the spec breaks visibly when
they do.

The same `Accept` update settles the same-day race. Both parents can hold proposals
naming one day, which Rule 6 makes the same swap. Clearing by named day, not by
proposer, voids the loser at the moment the winner lands.

## Actor-free actions

`Accept(p)` is indexed by the proposer whose proposal resolves, not by the parent who
accepts. The interface hides whose hand moved, so an actor parameter doubles the
action space for zero observable difference. The same reasoning collapses withdraw
and decline into one `Drop`.

## Obligations rendered over Observe

Every graded formula reads `Observe`, and the action properties subscript on
`_Observe`, not `_vars`. That's §3.3's contract, and here the two subscripts agree
anyway, since `swapped` is recoverable from the custodian field given two parents.

The two opening conditions (properties 2 and 9's opening clause) are bare state
predicates under `PROPERTY`. I probed the channel rather than trusting it: a false
opening predicate is caught at the initial state and exits 13.

## Instance data lives in MCCustody

Function-valued constants can't be written in a cfg, so the instance operators sit in
`MCCustody.tla` and the cfgs bind `Base <- MCBase`, `Hol <- MCHol`. Instance operators
inside `Custody.tla` would bend the reference toward one instance. The handoff's
idle-designation run then costs one cfg line, `MCCustodyIdle.cfg`.

## Fairness on BeginDay only

`WF_vars(BeginDay)` and nothing else. Days begin without either parent's leave, and
nothing compels acceptance, so the parents' actions stay unfair. Property 9's
liveness clause holds on that one condition, and the window terminating at `today = H`
is a deadlock on purpose, so deadlock checking stays off.

## What I'd flag for the variant author

The spec never stores the swap count, the proposal history, or who proposed what.
If a variant needs one of those distinctions, the interface was designed not to see
it, and I'd expect the variant to be observationally equal rather than caught.
