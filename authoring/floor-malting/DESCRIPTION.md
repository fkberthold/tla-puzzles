# Floor malting

System description for the reference-solution author (V2-PLAN.md §9.4). It fixes
the system and leaves the representation open (§3.2). It isn't the learner-facing
statement, and nothing in it is worded for a learner.

Sections 1 to 4 are the hand-off. Paste them into the §9.4 brief as the
`<system description>`. Sections 5 and 6 are pipeline notes for central. Keep
them out of the author's brief and out of anything downstream of it.

Grid cell: task shape A, in a situation of a two-sided window advanced by work
(S4). The learner writes the state, so the modeling choices in section 5 are the
problem rather than a footnote.

## 1. The system

Malting turns barley into malt. The grain is steeped in water until it wakes up,
then spread out to sprout, then dried with heat to stop it. Floor malting is the
old way of doing the middle part. The wet grain lies in a bed on a stone floor,
and men with wooden shovels turn it by hand. Nothing below needs any brewing
knowledge that isn't stated here.

A bed of grain lying on the floor is a **piece**. As a piece sprouts, the starch
in the grain breaks down into something a brewer can use. How far that has gone
is the piece's **modification**. Turning a piece with a shovel is what carries it
further, and nothing else does. Left alone, a piece goes nowhere.

**The parties.** One kind. A fixed, finite set of **maltsters**, named by
`Maltsters`, work the floor. Every step in this system is a maltster's. There's
no clock, no calendar, and no step that happens on its own. Nothing coordinates
them. Any maltster's next act can land between any two acts of another, and no
two act at once.

### Rule 1. The pieces

`Pieces` is a fixed, finite set, named up front. A piece is whole. It's never
split, never merged with another, and never renamed. At any moment a piece is in
exactly one of three places: down on the floor, gone to the kiln as good malt, or
thrown out as a loss. Every piece starts down on the floor, unturned.

### Rule 2. Modification, and the two marks

A piece's modification is the number of times it's been turned. It starts at
nothing and it's the only measure of the piece this system keeps.

Two numbers matter. Below `LowerMark` the piece is green. The starch hasn't
broken down far enough, and malt made from it is thin stuff. From `LowerMark` up
to but not reaching `UpperMark` the piece is ready, and that's when a brewer
wants it. At `UpperMark` the piece has gone over. The rootlets have grown long
enough to knit the bed into a solid mat, and a matted piece is ruined.

Real modification is a continuous thing a maltster judges by hand and by eye.
This system counts turnings instead, and says so.

### Rule 3. Turning

A maltster turns a piece that's down on the floor and hasn't gone over. The
turning raises that piece's modification by one and changes nothing else. A
maltster turns one piece at a time.

A piece that has gone over can't be turned. That isn't a policy anybody could
relax. A matted bed is one solid slab, and a shovel won't break it up.

### Rule 4. Kilning

A maltster takes a piece off the floor to the kiln. A piece that was ready comes
out as good malt. A piece that was green, or that had gone over, is a loss and
the fuel is wasted. The kiln is outside this system. Nothing about it is modeled,
nobody there acts, and a piece sent to it has left the floor for good.

### Rule 5. Throwing out

A maltster shovels a piece off the floor and throws it out. That piece is a loss.
This is what becomes of a matted piece, and of any piece a maltster judges isn't
worth the fuel.

### Rule 6. Two ways off, and no way back

Kilning and throwing out are the only ways a piece leaves the floor. Once a piece
is off, it stays off. It never comes back to the floor, its place never changes
again, and a loss never turns into good malt. There's no re-steeping and no
second try.

### Rule 7. The floor gets cleared

A malting floor is a working floor, and the next steeping needs the room. Every
piece down on it comes off, one way or the other. A maltster can take his time,
and he can leave a piece lying for as long as he likes, but he can't leave it
lying forever.

## 2. What must be true

A correct model satisfies all of these. They're stated in English here, over the
observables of section 3. The author renders them as properties of their model.

1. **The opening.** Every piece is down on the floor, and none has been turned.
2. **The count belongs to the floor, and it stops at the mark.** A piece down on
   the floor has a modification, and it's never above `UpperMark`. A piece off
   the floor has no modification at all.
3. **One pair of hands.** In any step, at most one piece's record changes.
4. **Turning adds one.** A piece on the floor before a step and on the floor
   after it either keeps its modification or gains exactly one. It never loses
   any.
5. **Good malt comes from a ready piece.** A piece becomes good malt only in a
   step where, just before it, that piece was on the floor with its modification
   at `LowerMark` or above and below `UpperMark`.
6. **Off the floor is final.** Once a piece is off the floor, its record never
   changes again.
7. **The floor gets cleared.** Every piece down on the floor is off it
   eventually.

Item 2 is a claim about a single state, so it's an invariant. Item 1 is a
condition on the opening state, before any step runs, so it's a state predicate
read as a temporal formula. Items 3, 4, 5 and 6 each compare a record at two
consecutive moments, so they constrain steps and land as action properties. Item
7 is the only one that needs "eventually", and it's the one liveness obligation
in this description.

The fairness conjunct sits on one step, and that step is the removal of a named
piece from the floor. Read it per piece: for each piece, weak fairness on any
maltster's act of taking that piece off, whether the act is a kilning or a
throwing out. Both acts have the same effect on the piece, so the disjunction
across them still obliges something. Don't put fairness on "a maltster acts".
Turning is something a maltster does, so that form obliges no removal at all, and
it's the shape to check for first when item 7 passes and shouldn't.

Every step rule above is checked over the whole of `Observe`, so the subscript is
`Observe` itself and never one of its fields. Subscript a rule on the place field
alone and every turning slips past it. Subscript it on the count alone and every
piece leaving the floor slips past.

The type invariant is the reference author's. It's declared in the cfg and it
counts as one of the lines there, and it's never something the learner is asked
to produce.

Seven items plus that type invariant makes eight lines in the cfg.

Each item breaks on a short finite trace, which is what §3.9 needs downstream.
Item 1 falls in the opening state, with one piece already turned once. Item 2
falls in a single state, and it falls two ways: a floor piece one turning past
`UpperMark`, or a piece already off the floor still carrying a count. Item 3 falls
on one step, two pieces turned together. Item 4 falls on one step, a floor piece
going from one turning to three. Item 5 falls on one step, an unturned piece
coming out of the kiln as good malt. Item 6 falls on one step, a piece thrown out
and then lying on the floor again. Item 7 is the liveness one, so its violating
trace is a finite prefix and then nothing more happens: two pieces get cleared,
the third lies on the floor, and from there the behavior stutters forever with
that piece still down. Every one of the seven is satisfied by an ordinary run of
the system.

## 3. The observation operator

The operator is named `Observe`. Each field is a fact about the floor right now,
the kind a maltster could call out walking the length of it. The fields are given
here as named facts, not as syntax. The author renders them over whatever state
they chose, one field per line.

**stage**: for each piece, where it stands now. Down on the floor, gone to the
kiln as good malt, or thrown out as a loss. Every must-be-true reads it, and
without it none of them can be stated at all.

**modification**: for each piece down on the floor, how many times it's been
turned. For a piece off the floor, a none marker. Needed by must-be-trues 1, 2, 4
and 5. The count and the place are tied together, and must-be-true 2 is what ties
them. A kilned piece still carrying a count is a malformed reading of the floor,
and I'd rather grade that than leave it to whatever shape the type invariant
happens to take.

**Why the count isn't typed to the marks.** This is the one real decision in the
operator, so it gets said plainly. A modification is a count of turnings, and
counting has no ceiling. What stops the count is Rule 3, which is a rule of the
system and not a fact about numbers. So the type invariant should say a floor
piece's modification is a natural number, and must-be-true 2 is what holds it at
`UpperMark`. Type it as a range ending at `UpperMark` instead and 2 is true by
construction, the learner writes `TRUE` in a costume, and TLC passes it. The
state space stays finite either way, because Rule 3's guard is what bounds it. I
think this is the trap worth naming here, since a bounded range looks tidier than
the honest typing.

**What the fields don't do.** A field says what must be reportable from the
state, not what the state is. `Observe` shows the floor and not the hands on it,
so who took a step is invisible here. "A maltster turns the piece" can't be a
property of any model, whatever fields you add. What is gradeable is the shape of
the change, one piece at a time and one turning at a time. That's must-be-trues 3
and 4, and between them they say nothing sweeps the whole floor at once and
nothing advances without a hand.

**Sufficiency walk.** The test in each row is which property constrains the rule,
never which field mentions it. A rule a field names and no property constrains is
loose. First, what each must-be-true reads:

| Must-be-true | Reads |
|---|---|
| 1 The opening | stage, modification |
| 2 The count belongs to the floor | stage, modification |
| 3 One pair of hands | stage, modification |
| 4 Turning adds one | stage, modification |
| 5 Good malt from a ready piece | stage, modification |
| 6 Off the floor is final | stage, modification |
| 7 The floor gets cleared | stage |

Six of seven rows read both fields. With a two-field operator that's what an
honest table looks like, and it isn't a sign the fields are redundant. The
operator has two fields because there are two things to read off a piece, where
it stands and how far it's come.

Then each rule, against the properties that constrain it:

| Rule | Constrained by |
|---|---|
| 1 The pieces | The three places are the type invariant, a real cfg line and not a shape argument. Must-be-true 1 fixes where every piece starts, and 2's first clause ties the count to the floor. The one-place-at-a-time clause rides `stage`'s shape, since a piece has one stage value and there's nowhere to record a second |
| 2 The two marks | 2 holds the ceiling. 5 grades both marks at once, by naming the window a piece has to be inside to come out as good malt |
| 3 Turning | 2 for the guard, 4 for the size of the step, 3 for one piece at a time |
| 4 Kilning | 5, in both directions. Ready is what lets a piece come out as good malt, and anything else forces a loss. The kiln has no observable of its own, which is the point of putting it outside |
| 5 Throwing out | 3 and 4 for the shape of the step, 6 for what happens after. Whether a throwing out could yield good malt is ungraded, and the paragraph below says why |
| 6 Two ways off, no way back | 6, which also closes the way in. That row is worth reading twice |
| 7 The floor gets cleared | 7, the one liveness obligation |

**The way in.** There's no entry step here, because every piece starts down on
the floor. So the only way a piece could arrive on the floor is by coming back
from off it, and must-be-true 6 forbids exactly that. With `Pieces` fixed and
`stage` total over it, there's no fourth place for a piece to arrive from either.
My read is that the way in, the ways out and the ways between are all graded, and
I'd still put a reviewer's eye on it, because a way in nobody grades is the
easiest thing in this form to leave open.

Two things are ungraded above and I'd rather name them than let a reader find
them. `Observe` can't tell a kilning from a throwing out. Both take a piece off
the floor, and what the interface shows is where the piece went. So a model with
one exit act whose outcome falls out of the modification is as correct as a model
with two acts, and Rule 5's clause that a throwing out is always a loss grades
nothing on its own. The other is Rule 3's "a maltster turns", for the reason two
paragraphs up. Everything else is constrained, and every field earns its place
through at least one must-be-true, so nothing in the operator is decoration.

## 4. Bounds

TLC must check the suggested instance exhaustively in well under a second. Every
bound below is a fact of the system first and a finiteness device second, and
each one already sits inside a rule the model has to enforce as behavior.

- **`Pieces`**: the beds down on the floor. The config picks one instance and the
  rules hold for any.
- **`Maltsters`**: the hands working the floor. Same.
- **`LowerMark`** (Rule 2): where the malt is far enough along to be worth
  kilning.
- **`UpperMark`** (Rule 2): where the bed mats and the piece is ruined. Above
  `LowerMark` in every instance. A window that isn't a window makes every piece a
  loss and grades nothing.

**Suggested instance**: 3 pieces, 2 maltsters, `LowerMark` 1, `UpperMark` 3.

Each bound bites at these values. A piece at nothing is green, so the early side
of the window is reachable in the opening state. A piece at one turning or two is
ready, so the window is an interval and a ready piece can be turned again and
stay ready. A piece at three has gone over and can't be turned, so the late side
is reachable and its only exit is a loss. Three pieces is the least that puts one
piece in each of the three places at once.

The arithmetic. A floor piece's modification is 0, 1, 2 or 3, so four records. A
piece off the floor is good malt or a loss, so two more. All six are reachable,
and the pieces don't touch each other, so I make it 6 to the third, or 216, and
that's the count rather than a ceiling on it. It's still arithmetic. Nobody has
run it, and 216 counts what `Observe` shows and not whatever else the reference's
own state carries.

The maltsters add nothing to that if each maltster's body is one atomic step,
since they carry no state of their own. A body with several labels multiplies the
count by the labels each maltster can sit at. Two labels each takes it to 864,
under a thousand but close, and I think a single-label body is the right shape
here anyway. If the count runs high, drop to 2 pieces, which takes it to 36.

**Quiescence.** When every piece is off the floor, no act is enabled and the
system stops. That's the intended end of the story, not a fault. A checker
reporting deadlock there is reporting the design working, and the reference
author should handle it in the config rather than by inventing a stuttering act
the maltsters don't have.

## 5. Open forks

The learner writes the state, so these forks are the problem. Each line below is
a choice the rules don't make, and the wording in sections 1 to 4 is meant to
keep it that way.

- **Modification**: a counter per piece, a sequence of turnings, or a set of
  them. The rules need a count reportable per floor piece and nothing more.
- **Where a piece stands**: a status per piece, or a partition of `Pieces` into
  three named sets.
- **The loss**: one exit act whose outcome falls out of the modification, or two
  acts, a kilning guarded to ready pieces and a throwing out.
- **The marks**: two constants compared against the count, a set of ready counts,
  or a pair of predicates.
- **The maltsters**: a process set with one atomic body, or bare actions
  quantified over `Maltsters`. Neither carries state.
- **Fairness**: which of the two exit shapes the conjunct sits on. Either way
  it's per piece, and the step it names is the removal of that piece.

The loss fork is the one that matters. A learner who carries "gone over" as a
fact he stores and a learner who reads it off the count write different step
rules, and neither of them is wrong. That's where representation 2 earns its
level, so nothing in sections 1 to 4 should be tightened in a way that picks one.

**One thing that isn't a fork.** At representation 2 the reference's variables
are the `Observe` fields and no others. So the reference carries a place and a
count, and no third variable and no history variable. If it ships as PlusCal,
`pc` is the translator's bookkeeping rather than a modeling choice, and my read
is that it doesn't push the row to representation 3. That's central's call on the
vector record rather than mine, and it's worth settling before the record is
written.

**What I took from the domain sketch, and what I changed.** The sketch offered
seven rules. Five came through close to their wording. Two didn't.

"A kilned piece is good or lost, never both" is gone. With one place value per
piece there's nowhere to record both, so the claim is the type invariant wearing
a different hat. A field's shape carries a rule only when the shape makes the
violating state unrepresentable, and this one does. I'd rather spend the line on
must-be-true 1, which the sketch didn't have, and which is the only thing grading
where a piece starts.

"A piece kilned below the lower mark is a loss" became must-be-true 5, which
grades both marks in one line. The sketch's version grades the early side only,
and the late side is half of why this domain was picked. I also added must-be-true
3, one pair of hands. Without it a single step can turn the whole floor and
nothing catches it.

## 6. Ambiguities resolved, and how they could have gone

1. **Floor capacity.** The floor holds every piece at once. No cap, no queue, and
   no competition for room. A floor with fewer places than pieces is allocation,
   which is a different situation and a burned one.
2. **The kiln.** Outside the system, and it takes any piece at any time. A kiln
   with a capacity brings that same allocation back through the other door.
3. **Every piece starts down.** No steeping step, no spreading step, and no
   fourth place. The alternative adds a way in, and a way in needs a property to
   grade it. I'd rather grade the opening state than add an act.
4. **Modification is a count of turnings.** Not temperature, not moisture, not
   hours. Real modification is continuous, and continuous takes the state space
   past what this rung can hold. §3.2 lets the description fix the system, so
   Rule 2 fixes it by fiat and says so.
5. **A matted piece can't be turned.** That's what stops the count from running
   away. The alternative lets a maltster keep shoveling a ruined bed, and then
   the ceiling has to come from somewhere that isn't a fact of the system.
6. **Who acts first.** Nobody. The maltsters interleave freely, and the opening
   is the same however they work.
7. **Nothing is undone.** A piece off the floor stays off. Returned malt and
   re-steeping are both real in the trade, and modeling either kills must-be-true
   6 and most of the system's shape with it.
8. **The floor must get cleared.** The maltsters are under an obligation. A lazy
   floor is the live alternative, and it's what I'd take if this rung wanted
   safety only. Take it and there's no liveness here at all, and no fairness
   conjunct to decide.
9. **The maltsters carry nothing.** No shovel to hold, no piece assigned to a
   man. A maltster who can work one piece at a time is allocation again.
10. **Kilning and throwing out look alike at the interface.** Said in section 3
    and repeated here, because a reviewer will hunt for the missing property.
    Nothing tells them apart in `Observe`, so no property can.
11. **After the floor is clear.** Nothing more happens. That's the end of the
    story, and section 4 says what a checker will make of it.
12. **No plant, and no equipment.** A maltings is a food plant, and Frank works
    in control and refrigeration for food and beverage processing. There's
    nothing here about temperature, air, water, instruments, alarms or machinery.
    The kiln is named as a place a piece goes and is never described. Floor
    malting is the right domain because the maltster judges by hand and no
    instrument tells him anything, and that's the line to hold if a downstream
    author reaches for plant.
13. **The word for the failure.** A neglected bed heats as well as mats. I've
    written the failure as matting alone and left the heat out, for the reason in
    item 12.
14. **The word "expiry".** `harness/screen.sh:112` carries a map row whose bare
    `expiry` alternative fires on any S4 phrasing and returns BURNED. The screen
    report for this rung has the one-word probe that shows it and a follow-up to
    split the row. A statement author who writes "expiry" here gets a burned
    verdict on a domain with no blood bank anywhere in it. Use the word if the
    statement needs it, and let this record carry the reason.
