# State alternatives, considered and rejected

Author-only note for the seedlib reference (V2-PLAN §9.4). Downstream blind
agents must have no path to this file.

## What I chose

Four variables, one per `Observe` field. `season` runs 1..4, with 4 as the end
mark. `shelf` maps variety to count. `owed` maps member, then variety, to a
count. `standing` maps member to `"good"` or `"default"`. `Observe` is the
identity record over the four.

The observation fixes the fields, and no rule needs state the fields leave
out. So the cheapest correct representation is the observation itself. I
looked for state that earns more than that and didn't find any.

## Rejected: packet identities

Rule 1 gives each packet its own history, so a bag of packet records was the
first candidate. But the librarian goes by the label, and no property reads
identity, generation, or provenance. Identities would multiply states with
nothing to catch the difference. Counts are the whole census.

## Rejected: shelf derived from the ledger

Conservation ties the shelf to the ledger, so `shelf` could be a definition
over `owed` instead of a variable. That bakes property 5 into the
representation, and the handoff is plain that grading has to see the models
where the count doesn't follow. A free variable keeps `ConservationInKind`
falsifiable. I suspect a derived shelf is also the shortcut a strong learner
reaches for, and the reference shouldn't share it.

## Rejected: owed as a set of pairs

A set of member-variety debts reads well and can't count to two. The
observation demands a count, and property 4 is about that count passing one.
A representation that can't show the violation can't anchor the variant that
commits it. The same reasoning kills a boolean owes-function.

## Rejected: season as strings

Names like "first" and "ended" match the prose. But the calendar's march is
an order, and strings need a hand-built successor. Numbers carry the order
and the one-step march for free, and `Ended == NumSeasons + 1` keeps the end
on the same axis.

## Rejected: NumSeasons as a constant

Section 2 of the handoff names three constants: members, varieties, opening
stock. Rule 2 makes the horizon part of the program, not a parameter. So
`NumSeasons == 3` is a definition, and the cfg has nothing to say about it.

## Rejected: per-debt age

I considered tagging each debt with its season of origin, for the late-return
fates in property 8. The handoff's own argument holds: default blocks
checkout, so a defaulter's debts are all past-season, and standing already
carries what age would. No property reads age, so the field is dead weight.

## Smaller calls

- **standing as a defaulter set**: equivalent, but `Observe` rebuilds the function anyway.
- **fairness on `Close` only**: the calendar is the one party that must act.
- **`SumOver` written recursively**: standard modules only, no community folds.
- **MC split**: the cfg can't write a function constant, so `MCSeedLib` holds the instance.
