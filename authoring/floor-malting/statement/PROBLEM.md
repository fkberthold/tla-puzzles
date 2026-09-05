# The malting floor

Malting turns barley into malt. The grain is steeped in water until it wakes
up, then spread out to sprout, then dried with heat to stop it. Floor malting
is the old way of doing the middle part. The wet grain lies in a bed on a
stone floor, and men with wooden shovels turn it by hand.

Your job is to model that floor, and to check seven requirements against your
model.

You don't need to know anything about brewing. Every rule the floor follows is
stated below.

## What you get

- The rules, and the seven requirements they carry.
- `traces/`: pairs of runs. In each pair, one run the floor can produce and one
  it can't.

No model ships with this problem. The state is yours to design.

## Your task

1. Model the floor in PlusCal or TLA+. Pick whatever state you like, in
   whatever shape you like.
2. Define `Observe`, the record described under the interface below.
3. Write each of the seven requirements as a formula over `Observe`.
4. Declare each one under the keyword its requirement names.
5. Run TLC at the checking instance. Your model must satisfy all seven.
6. Hold your model against the traces. Every run the floor can produce must be
   a run your model allows. Every run it can't must break at least one of your
   properties.

Deliver your module and the `.cfg` you checked it with.

## The system

**The parties.** One kind. A fixed, finite set of **maltsters** works the
floor. Every step in this system is a maltster's. There's no clock, no
calendar, and no step that happens on its own. Nothing coordinates them. Any
maltster's next act can land between any two acts of another, and no two act
at once.

A bed of grain lying on the floor is a **piece**. As a piece sprouts, the
starch in the grain breaks down into something a brewer can use. How far that
has gone is the piece's **modification**. Turning a piece with a shovel is
what carries it further, and nothing else does. Left alone, a piece goes
nowhere.

### Rule 1: the pieces

`Pieces` is a fixed, finite set, named up front. A piece is whole. It's never
split, never merged with another, and never renamed. At any moment a piece is
in exactly one of three places. It's down on the floor, or it's gone to the
kiln as good malt, or it's been thrown out as a loss. Every piece starts down
on the floor, unturned.

### Rule 2: modification, and the two marks

A piece's modification is the number of times it's been turned. It starts at
nothing, and it's the only measure of the piece this system keeps.

Two numbers matter. Below `LowerMark` the piece is green. The starch hasn't
broken down far enough, and malt made from it is thin stuff. From `LowerMark`
up to but not reaching `UpperMark` the piece is ready, and that's when a brewer
wants it. At `UpperMark` the piece has gone over. The rootlets have grown long
enough to knit the bed into a solid mat, and a matted piece is ruined.

Real modification is a continuous thing a maltster judges by hand and by eye.
This system counts turnings instead, and says so.

### Rule 3: turning

A maltster turns a piece that's down on the floor and hasn't gone over. The
turning raises that piece's modification by one and changes nothing else. A
maltster turns one piece at a time.

A piece that has gone over can't be turned. That isn't a policy anybody could
relax. A matted bed is one solid slab, and a shovel won't break it up.

### Rule 4: kilning

A maltster takes a piece off the floor to the kiln. A piece that was ready
comes out as good malt. A piece that was green, or that had gone over, is a
loss and the fuel is wasted. The kiln is outside this system. Nothing about it
is modeled, nobody there acts, and a piece sent to it has left the floor for
good.

### Rule 5: throwing out

A maltster shovels a piece off the floor and throws it out. That piece is a
loss. This is what becomes of a matted piece, and of any piece a maltster
judges isn't worth the fuel.

### Rule 6: two ways off, and no way back

Kilning and throwing out are the only ways a piece leaves the floor. Once a
piece is off, it stays off. It never comes back to the floor, its place never
changes again, and a loss never turns into good malt. There's no re-steeping
and no second try. A piece off the floor has no modification either. The count
belongs to the bed lying on the stones, and it goes when the bed does.

### Rule 7: the floor gets cleared

A malting floor is a working floor, and the next steeping needs the room.
Every piece down on it comes off, one way or the other. A maltster can take
his time, and he can leave a piece lying for as long as he likes, but he can't
leave it lying forever.

## The interface

Your model defines one operator, `Observe`, a record with two fields. Grading
reads `Observe` and nothing else. Your variables never leave your module. Pick
whatever state you like, and render these two facts from it. Each field is the
kind of thing a maltster could call out walking the length of the floor.

- **stage**: for each piece, where it stands now.
- **modification**: for each piece down on the floor, how many times it's been
  turned. For a piece off the floor, a marker saying there's no count.

The shapes are fixed, because grading compares values.

- `Observe.stage` is a function from `Pieces` to `{"floor", "malt", "loss"}`.
  Those three are rule 1's three places, in rule 1's order.
- `Observe.modification` is a function from `Pieces`. Each value is either a
  natural number or `NoCount`.

`NoCount` is a fifth constant your module declares, alongside the four the
rules name. Declare it in your `.cfg` as a model value, by writing
`NoCount = NoCount`. Don't reach for a string. TLC raises on `"none" \in Nat`
and on `0 = "none"` instead of answering `FALSE`, so a string marker turns a
check that should fail into a run that stops partway. A model value compares
against a number and gets `FALSE` without complaint.

The same hazard sits in your step rules. A comparison against `LowerMark` or
`UpperMark` is arithmetic, and the marker isn't a number. Guard every such
comparison on the piece being down on the floor. Forget the guard and TLC
stops the run with an evaluation error, which is not the same thing as a
property failing.

Don't type the count to the marks. A modification is a count of turnings, and
counting has no ceiling. What holds the count down is rule 3, which is a fact
about the floor and not a fact about numbers. A field typed as a range ending
at `UpperMark` makes requirement 2 hold by construction and catch nothing,
whatever your step rules do.

## The requirements

Seven of them. Each one says which keyword to declare it under and what kind
of formula it is. The formula itself is yours.

### Requirement 1: the opening

Every piece is down on the floor, and none has been turned.

This is a claim about the opening state, before any step runs. Write it as a
state predicate over `Observe` and declare it under `PROPERTY`. TLC reads a
state predicate declared there as a claim about the states your model starts
in.

### Requirement 2: the count belongs to the floor, and it stops at the mark

A piece down on the floor has a modification, and it's never above
`UpperMark`. A piece off the floor has no modification at all.

This is a claim about a single state, so write it as a state predicate.
Declare it under `INVARIANT`.

### Requirement 3: one pair of hands

In any step, at most one piece's record changes.

This compares a record at two consecutive moments, so it's an action property.
Write it in the form `[][A]_Observe` and declare it under `PROPERTY`.

Subscript it over the whole of `Observe`, never over one of its fields. A step
rule watched over a single field is satisfied for free by any step that changes
only the other field. TLC won't warn you. The property just stops seeing the
steps it was written about.

### Requirement 4: turning adds one

A piece on the floor before a step and on the floor after it either keeps its
modification or gains exactly one. It never loses any.

Action property. Write it in the form `[][A]_Observe` and declare it under
`PROPERTY`. The warning about the subscript applies here, and to every action
property below.

### Requirement 5: good malt comes from a ready piece

A piece becomes good malt only in a step where, just before it, that piece was
on the floor with its modification at `LowerMark` or above and below
`UpperMark`.

Action property. Write it in the form `[][A]_Observe` and declare it under
`PROPERTY`.

### Requirement 6: off the floor is final

Once a piece is off the floor, its record never changes again.

Action property. Write it in the form `[][A]_Observe` and declare it under
`PROPERTY`.

### Requirement 7: the floor gets cleared

Every piece down on the floor is off it eventually.

This is the one requirement that needs "eventually". Write it as a temporal
formula over `Observe` and declare it under `PROPERTY`.

It's also the one that puts a demand on your `Spec`. Your `Spec` needs a weak
fairness conjunct per piece, on a maltster's act of taking that one piece off
the floor, whether that act is a kilning or a throwing out. Weak fairness on
your whole next-state relation isn't what rule 7 says. Rule 7 is about each
piece coming off, so the conjunct names the step that takes a piece off.

## The traces

The runs under `traces/` witness the requirements, one pair per requirement.
Each state shows the two `Observe` fields. Consecutive states are one step
apart.

- **A run the floor can produce.** Your model must allow it.
- **A run the floor can't produce.** Your properties must rule it out.

Three notes:

- A forbidden run can break more than one requirement. If your set rejects it
  for any requirement it breaks, your set is right about that run.
- Where a forbidden run's fault is that nothing more ever happens, the trace
  says so under its last state.
- If your model can't produce the allowed run of every pair, it's
  over-constrained, however green your checks are. That's the failure the
  allowed runs are here to catch.

## Checking

Five constants: `Pieces`, `Maltsters`, `LowerMark`, `UpperMark` and `NoCount`.
`UpperMark` sits above `LowerMark` in every instance. A window that isn't a
window makes every piece a loss and checks nothing.

Use the instance the traces use:

```
Pieces = {p1, p2, p3}
Maltsters = {m1, m2}
LowerMark = 1
UpperMark = 3
NoCount = NoCount
```

Turn deadlock checking off. Put `CHECK_DEADLOCK FALSE` in your `.cfg`, or pass
TLC the `-deadlock` flag, which despite its name turns the check off. When
every piece is off the floor, no act is enabled and the run stops. That's the
story ending, not a fault.

At that instance your run should find at least 216 distinct states. That's
what the two fields can show between them: four counts for a piece on the
floor, plus good malt and a loss, is six records per piece, and the pieces
don't touch each other. Fewer than 216 means your model can't do something the
floor can do. More than 216 is fine, and it's what you get if your state
carries a fact the interface doesn't ask for.
