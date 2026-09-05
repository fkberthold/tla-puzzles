# Alternatives considered (bonded-store reference)

Author-only note per V2-PLAN §9.4, written after the reference went green. It
records the state representations I weighed and why the shipped one won.

## What shipped

Two variables, `place` and `dutyPaid`. Each is a total function from a lot to a
place string or a boolean. `Observe` renders as the identity over them, field for
field. The state is the interface, so nothing in the model hides behind a
projection.

The run is 145 states generated, 64 distinct, depth 7, under a second at three
lots.

## Duty derived from place

The one that had to be refused, and I want the reason on the record rather than
in a reader's head. `dutyPaid[l] == place[l] = "released"` is shorter, and it
drops a variable. It also makes must-be-true 1 a tautology. The obligation stops
being a claim about the keeper's steps and becomes a claim about my own
definition, and TLC passes it either way.

My mutant probe is the concrete cost. With duty as its own variable I could write
a movement step that pays duty on a lot moved on under bond, and
`DutyMatchesPlace` caught it with rc=12. Under the derived form that mutant can't
be written at all. An obligation nothing can break isn't an obligation.

## One variable of per-lot records

`lot = [l \in Lots |-> [place |-> ..., dutyPaid |-> ...]]`, one variable instead
of two. It reads well and it keeps the two facts about a lot together.

I rejected it on the interface. Section 3 names two fields, so `Observe` would
have to project each one back out of the record, and the operator stops being a
plain record over state. That's the same call the qsl reference made for the same
reason. It's a legibility call, not a correctness one.

## Places as four sets partitioning Lots

Four variables, one per place, each holding the lots that sit there. Movement is
then a transfer between sets.

This one costs a cfg line, which is what killed it. Rule 1's one-place-at-a-time
clause rides the shape of a function and needs no property. Under a partition it
stops riding anything, because four independent sets can overlap or leave a lot
out. So the model needs a fifth obligation to say the sets partition `Lots`, and
five lines pushes property count off the rung.

## Places as a stage number

`place \in 0..3` with an order over the stages. Rejected because release and
movement under bond aren't ordered against each other. Both are terminal, both
leave the store, and neither follows the other. A number would invite a reader to
find a sequence that Rule 5 says isn't there, and it pulls in `Naturals` for
nothing.

## Places as model values

Declare the four places in the cfg as model values instead of writing them as
strings in the module. Section 4 settles this one. The four places are fixed by
the rules, so they belong in the module where the rules live. A cfg that can vary
them is a cfg that can model a store with three places, which isn't this system.

## Duty as an amount

A number of currency units instead of a flag, with release setting it to the
assessed duty. Rule 3 asks whether the duty is paid and never how much, so the
amount is state no obligation reads. It would also multiply the state space by
the range for nothing.

## One label, not several

The algorithm is a single `Keep` label wrapping a `with` and a three-way `either`.
The alternative is a label per action, which reads closer to the three rules.

I kept one label so the translation carries no `pc`. A program counter is state
the store's account can't show, and I'd rather not put a variable in the model
that `Observe` has no honest field for. One label also makes each keeper step
atomic, which is what Rule 3 means by paying the duty in the same motion.

## Quiescence

Section 4 says a checker reporting deadlock at the end of the story is reporting
the design working. Two ways to answer that. Add an idle action that stutters
when no lot can move, or turn the check off.

I turned it off, with `CHECK_DEADLOCK FALSE` in the cfg. The idle action would be
a step the statement assigns to nobody, and this system has one actor. Dropping
the line is what shows the setting is load-bearing: TLC then reports deadlock at
the state where all three lots are released.
