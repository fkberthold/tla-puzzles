# No refutation traces, and the reason is that the traces are the deliverable

This package ships no trace pairs. That's deliberate and it isn't a gap in the
authoring. Four routes were tried and each one was measured rather than argued.

Written 2026-10-08 against TLC2 Version 2026.07.31.184830, at the statement's own
checking instance of `Leaves = 3`, each requirement in its own `.cfg` as a formula
over `Observe` alone, action properties subscripted over the tuple of all four
fields, `-deadlock`.

## The deliverable is the runs

`PROBLEM.md:18-20` asks the reader to settle the eight and, "for each one that
isn't, produce a run that shows it". `PROBLEM.md:316-317` asks for "the shortest
run you found that breaks it". So a run shipped beside the statement is a
deliverable handed back.

That is the whole difference from `custody` and `progressive-sync-stale-status`,
whose trace directories do ship. In both of those every requirement holds of the
system, and a violating run comes from a model the reader shouldn't write. Here
two of the eight are false of the office, so a violating run for either one is
the answer.

## Requirement 1's state is reachable only through the office's own run

Requirement 1 is about a card that says the last leaf while the book is still in
the gang's hands. Getting there without also breaking requirement 5 needs the
desk's own authority standing on the last leaf, and that needs an entry landing
there that didn't take the book back.

Measured over the office, with `(leaf = Leaves /\ standing # "spent") => withdrawn`
declared as an `INVARIANT`:

```
rc = 0, 17 distinct states, depth 6
```

So the last leaf with the book still open is only reachable after a withdrawal.
Every legal route to requirement 1's state runs through the fire watch, which is
the first half of the office's own counterexample. That counterexample is rc 12
over 5 trace states, and shipping it settles requirement 1 for the reader.

## The one break that gets there legally signposts the withheld asymmetry

A model where a close entered on the last leaf doesn't fill the book reaches
requirement 1's state with no withdrawal anywhere. Measured: rc 12 over 3 trace
states, and it's the only break of the nine below that breaks requirement 1 and
nothing else.

It's also the one I'd least want to ship. The step 5 report records rule 7's
asymmetry as withheld, present as a rule and never named as the place the defect
lives. A file saying requirement 1 turns on rule 7 and the last leaf names it. The
reader who then asks what the withdrawal half does has the whole problem, and I
think that's a worse hand-over than the sentence the blocking edit removed.

## Breaking requirement 5 to get there doesn't reach the state

The second route was a model where the desk writes the book's last leaf onto the
card. It reaches a card saying the last leaf in two states, and it gets there by
putting the card ahead of the book. Measured on that same 2-state run: requirement
1 rc 12, requirement 5 rc 12, requirement 6 rc 13.

A trace pair only catches a wrong property if its forbidden run reaches the state
that property is about. This run reaches a card the office can't produce at all,
so a reader whose requirement 1 is wrong in any of several ways still sees it go
red. The pair would certify three formulas at once and discriminate none.

## Shipping the other seven fires two of the screen's own probes

The remaining seven breaks are clean and I'd ship them in another problem. Here
the hole is the leak.

`harness/PUZZLE-SCREEN.md:305` names the elimination route, "the only candidate of
its type", and the tiling route, "the artifact's own enumerated list set against
the statement's own, and the holes between them". Eight requirements and seven
files leave one hole, and the hole is the requirement the whole problem turns on.

A `README.md` denying the inference doesn't close it either. "A file here isn't
evidence the office keeps the requirement" is a passage saying this looks wrong and
it's fine, which is the pre-clearing probe on the same page.

## What carries the weight instead

`PROBLEM.md:296-310`, which already does this directory's job without naming a
verdict. It tells the reader to break something on purpose, works requirement 3 as
the example, and states the hard part plainly: a red check means either the office
lacks the property or the model isn't the office.

The nine breaks below belong in the step 6 reference, where a grader can use them
and a reader can't. Each one is a step or an opening the rules forbid, so each is a
model that's wrong rather than an office short of a property.

| requirement | the break | what the modeller got wrong | rc | trace states |
|---|---|---|---|---|
| 1 | `rule7` | a close on the last leaf doesn't fill the book | 12 | 3 |
| 1 | `cardGetsLast` | the desk writes the book's last leaf onto the card | 12 | 2 |
| 2 | `noWatch` | the fire watch never goes round | 13 | 3 |
| 3 | `backToCard` | a second copy moves the desk's leaf back to the card | 13 | 3 |
| 4 | `skipLeaf` | an entry lands on the leaf after the next one | 13 | 2 |
| 5 | `cardStartsLoose` | the card starts on any leaf, not on leaf 1 | 12 | 1 |
| 6 | `cardResets` | a close writes leaf 1 onto the card | 13 | 4 |
| 7 | `withdrawClears` | a withdrawal clears the book instead of abandoning it | 13 | 3 |
| 8 | `spentCompletes` | the desk marks a full book completed and carries on | 13 | 4 |

Four of them light up a second requirement, and two of those pairs look structural
rather than accidental to me. `cardGetsLast` breaks 1, 5 and 6 together, because a
card ahead of the book moves to a leaf that isn't the one the desk holds.
`backToCard` breaks 3 and 4 together, because a leaf that moves backwards hasn't
moved on by one. `cardStartsLoose` breaks 1 and 5, both in the initial state and
with no step at all. I didn't find a single-step break for requirement 5 that
leaves requirement 6 alone, and I suspect there isn't one.

## One hazard for whoever tries this again

Every one of the nine breaks reports requirement 1 at rc 12 and requirement 2 at
rc 13, whatever else it does. Those two are false of the office, so a broken model
inherits the office's counterexample along with its own. Read the action names in
TLC's trace rather than the exit code, or you'll write up the answer by accident.

## Lineage

Bead `tla-pmm2.2`. Step 5 report at `../../reports/step5-consistency.md`. The
pattern this package shares with `acme-challenge-retry-deadlock` is bead
`tla-n8oq`, and that problem's own `traces/NONE.md` is the shape this file follows.
