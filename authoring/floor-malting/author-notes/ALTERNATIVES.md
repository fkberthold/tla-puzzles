# Alternatives considered (floor-malting reference)

Author-only note per V2-PLAN §9.4, written after the reference went green. It
records the state representations I weighed and why the shipped one won.

## What shipped

Two variables, `stage` and `modification`, both functions over `Pieces`.
`Observe` renders as the identity over them, field for field. The state is the
interface, which is what the rung's representation level asks for.

## Plain TLA+ rather than PlusCal

The rung pins the reference's variables to exactly the `Observe` fields. A
PlusCal process set over `Maltsters` carries a `pc`, and a `pc` is a third
variable that isn't a field. One label per process elides it, but a set of
maltsters with a single `Keep:` loop still gets one. So `Init`, `Next` and
`Spec` are written by hand. The cost is that the module reads less like the
ch.11 material. I think that's the right trade here, since nobody ships this
one to a learner.

## The none marker, and why it's a model value

This is the one thing that changed under me, so it gets said plainly. The
first draft used the string `"none"` for a piece off the floor. TLC refuses
it. `"none" \in Nat` raises `Attempted to check if the value "none" is an
element of Nat`, and reordering the disjunction just moves the failure to
`0 = "none"`, which raises `Attempted to check equality of integer 0 with
non-integer`. Both are evaluation errors, not property violations, so the run
comes back `TLC_EXCEPTION` at rc=255 rather than telling you anything.

A declared model value fixes it. TLC compares a model value with any other
value and gets `FALSE` without complaint. That's why `NoCount` is a fifth
constant rather than a literal in the module, and it's the only constant here
that isn't one of the description's four bounds.

The alternative I looked at was making the marker a set, `{n}` on the floor
and `{}` off it. Set equality never raises, so it works. I rejected it because
the field stops being a count. The description says a floor piece's
modification is how many times it's been turned, and a singleton set is a
container for that number instead of the number. Costing a constant is
cheaper than costing the field's meaning.

The trap here is worth naming for whoever writes the seeded variants. Two of
the seven violating traces the description asks for, item 2's off-floor piece
still carrying a count and item 6's thrown-out piece back on the floor, both
put an integer next to the marker in an equality. Under a string marker those
traces blow up instead of failing. Under a model value they fail cleanly.

## Typing the count as `Nat`

The description makes this call and I followed it, but I want the reason on
the record rather than deferred. `TypeOK` says a modification is either
`NoCount` or a natural number, with no ceiling. Rule 3's guard on `Turn` is
what bounds it at `UpperMark`, and the state space stays at 216 either way.
Type the field as `0..UpperMark` and must-be-true 2's ceiling clause holds by
construction, so the obligation grades nothing.

## `TypeOK` doesn't tie the count to the place

`TypeOK` is a shape claim and nothing more. It allows a floor piece carrying
`NoCount` and an off-floor piece carrying 2, and `CountBelongsToTheFloor` is
what rules both out. Folding the tie into `TypeOK` would have been tidier to
read, and it's what I'd write if the type invariant were the only line. Here
it would make item 2's first and third clauses true before the learner writes
anything, which is the same failure as the bounded range one section up.

## One exit act or two

`Kiln` and `ThrowOut` are separate actions that agree on everything `Observe`
can see. A single `Leave` action whose outcome falls out of the modification
would be observationally identical, and the description says so. I kept two
because `GoodMaltComesFromReady` reads as a claim about the kiln, and a
reader tracing the property back wants an action with that name to land on.
The description also says a throwing out is always a loss, and with one act
that rule has nowhere to live at all.

## Fairness

Weak fairness per piece on `\E m \in Maltsters : Remove(m, p)`. The live
alternative is `WF_vars(Next)`, or weak fairness on any maltster acting, which
clears the floor here for a real reason. Rule 3 caps the turnings a piece can
take, so only finitely many acts are turnings and the rest take a piece off.
I'd take that form in a spec where the reader already knows the cap. In a
problem statement it names no step, and the learner has to rebuild the
counting argument before the conjunct means anything.

Fairness on the disjunction across `Kiln` and `ThrowOut` still obliges
something, since both acts move the piece off the floor. Splitting it into two
per-act conjuncts would oblige more than the description asks, because it
would force every piece through both exits.

## The maltsters carry no state

`Maltsters` is quantified in `Next` and inside the fairness conjunct, and
nothing indexes state by it. Dropping the parameter altogether would give the
same reachable state graph and the same 216 states. I kept it because the
rung's step-sources level is read off the parties in the module, and an action
with no maltster in it leaves that reading with nothing to cite. It also keeps
`Turn(m, p)` honest about who turns a piece.

## Quiescence

Every piece off the floor is the end of the story, so nothing is enabled and
TLC reports deadlock. `CHECK_DEADLOCK FALSE` in the cfg. The alternative is a
stuttering act the maltsters don't have, which invents a step to keep a
checker quiet. The description warns against it and I agree.
