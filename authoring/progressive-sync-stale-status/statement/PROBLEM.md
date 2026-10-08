# The superintendent's circulation

A railway runs on a rule book, and every signal box on the line holds a copy.
When the rules change, head office issues an amendment: a page to be pasted
into the book and worked to from then on. The superintendent of a region has
to get that amendment into every box she answers for.

She can't do it all at once, and she wouldn't want to. Her boxes are grouped
into districts, and the districts go in a fixed order. A quiet branch line
first, then one busy junction, then the main line. If an amendment is going to
cause trouble, she'd rather meet it on the branch. So a district doesn't start
until the one before it is done. On the last district she takes fewer at a
time still.

Her difficulty is that she can't see into a signal box. What she has is a
board. The board carries one line per box, saying how that box stood when it
was last looked at. A clerk keeps the board. He goes round the boxes and
writes down what he finds. The round is his and not hers, and nothing in the
circulation waits on it.

Model this, and establish the seven requirements below. The rules fix what
happens. How you model it is up to you: your state, your steps, TLA+ or
PlusCal. The one fixed point is the interface, a single operator the checker
reads.

Plan on 25 to 45 minutes if you've read the learntla core chapters. You don't
need to know anything about railways. Every rule the region follows is stated
here.

## What you get

- This statement: the rules, the interface, and the seven requirements.
- Two modeling choices the statement leaves open, in their own section.

No model ships. You write it.

## Your task

1. Model the region below, in whatever state shape you like.
2. Define `Observe` over your state, with the five fields the interface fixes.
3. Write each of the seven requirements as a formula over `Observe`, and
   declare it in your `.cfg` under the keyword the requirement names.
4. Run TLC at the checking instance, and fix your model until all seven hold.
5. Write down what you settled under each of the two open choices.

## The region

Four parties act, and they act independently.

- **Head office**, which issues the amendment and does nothing else here.
- **The superintendent**, one. She opens the circulation, issues the amendment
  to a box, signs off a district, and nobody else does any of those.
- **The clerk**, one. He goes round the boxes and keeps the board.
- **A signal box**, which pastes an amendment into its own book.

Nothing coordinates them. Any party's step can land between any two of
another's. There's no clock and no timetable, and nothing here happens except
by a party's own act.

### Rule 1. The boxes and the districts

`Boxes` is a fixed finite set of signal boxes, named up front. `Districts` is
a sequence of sets of boxes. The sets don't overlap and together they're the
whole of `Boxes`, so every box sits in one district and the districts carry an
order.

That order is the region's and the superintendent doesn't choose it. District
1 goes first, and the last one in the sequence goes last.

### Rule 2. The amendment

This covers one amendment. Until it's issued, the current amendment is the
standing edition the region has worked to all along. Head office issues the
amendment once, and nothing follows it.

Issuing it is head office's act. It's one step, it changes nothing but which
amendment is current, and it doesn't open the circulation. The superintendent
does that herself, by taking the first district in hand once the amendment is
current.

### Rule 3. What a box works to, and the hold

Each box works to one amendment at a time, and at the opening every box works
to the standing edition. A box moves by pasting a new amendment into its book,
and that's the box's own act.

Left alone a box would do it unprompted. The standing instruction is that a
signalman who finds his book behind the current amendment brings it up without
being told. The superintendent holds that instruction for the whole of a
circulation, so that no box jumps the order. Nothing in this system lifts the
hold, and signing off a district doesn't lift it for that district's boxes.

So while a circulation runs, a box pastes the amendment in only if she has
issued it to that box. A box she never issues never moves. Putting that right
takes a hand from outside the region, and this system doesn't model that hand.

### Rule 4. Issuing

The superintendent issues the amendment to a box of the district in hand. She
takes one box at a time, in whatever order she likes, and only a box she
hasn't got out already. A box she has issued that hasn't pasted in yet is
**under issue**.

A box under issue pastes the amendment in and stops being under issue. That's
a step of the box's, not of hers. She can't paste it in for him, and she
can't call an issue back.

### Rule 5. The cap on the last district

On the last district in the order she keeps the number under issue down to
`Cap`, a fixed count named up front. The earlier districts carry no cap, so
she can have every box of one of those under issue at once.

### Rule 6. The board and the clerk's round

The board carries one line per box. When the clerk looks at a box, that box's
line is brought into agreement with what he found there. Between his visits
the line stands as last written, however the box has moved since.

The round is the clerk's own. He takes boxes in whatever order he likes,
nothing in the circulation waits on him, and no step of hers makes him move.

### Rule 7. Signing off, and what she can read

The superintendent signs off the district in hand, and that puts the next
district in hand. Signing off the last district ends the circulation. A
sign-off is final and she never goes back to a district she has signed off.

She never sees into a box. Her own records she reads freely: which amendment
is current, which district is in hand, which boxes she has out, and which
districts she has signed off. Past those, the board is everything she has.
Whatever guards her sign-off is built out of her records and the board, and
out of nothing else.

This statement doesn't write that guard for you. It's the one thing in the
region left to you, and requirement 1 is what it has to meet.

### Rule 8. The opening

At the opening every box works to the standing edition, no amendment has been
issued, no box is under issue, no district is signed off, and no district is
in hand. The board agrees with every box, because the clerk has been round
since the last thing that changed.

### Rule 9. What must happen, and what needn't

The amendment has to reach every box. That's the one thing in this region that
must happen.

Three parties are on the hook for it. The superintendent may take her time
over any single step, but she can't sit on the whole business. A box under
issue pastes the amendment in sooner or later. And the clerk keeps going
round, so no box goes unvisited forever.

Head office owes nothing. No amendment need ever be issued, and a circulation
that never opens breaks no rule here.

## The interface

The checker never looks at your state. It evaluates one operator, `Observe`,
which your module defines over whatever state you chose. Each field is a fact
about the circulation right now.

```tla
Observe == [amendment |-> ..., working |-> ..., inHand |-> ...,
            underIssue |-> ..., signedOff |-> ...]
```

- **amendment**: the amendment now being circulated.
- **working**: for each box, the amendment that box works to.
- **inHand**: the district in hand.
- **underIssue**: the boxes she has out that haven't pasted in yet.
- **signedOff**: the districts she has signed off.

The shapes are load-bearing, because the checker compares values. A renamed
field, a sixth field, or a different spelling doesn't fail a check. It keeps
the check from ever running.

- `Observe.amendment` is a natural, `0` for the standing edition.
- `Observe.working` is a function from `Boxes` to naturals.
- `Observe.inHand` is a natural, numbered as below.
- `Observe.underIssue` is a subset of `Boxes`.
- `Observe.signedOff` is a subset of `1 .. Len(Districts)`.

`inHand` reads `0` before the circulation opens, `k` while district `k` is in
hand, and `Len(Districts) + 1` once the last district is signed off. Numbering
it that way keeps every field a number or a set of numbers, so no comparison
in a requirement meets a string sitting beside a natural. A string there stops
TLC dead instead of answering false.

**The board isn't a field, and that's on purpose.** The board is yours. Keep
it in whatever shape you settled on under rules 6 and 7, and nothing grades
it. A model with no board can still report all five fields correctly. It
can't state rule 7 at all, because its superintendent has nothing to read.

**`signedOff` is a fact her sign-off step sets, not a reading of `working`.**
Derive it from `working` and requirement 1 comes out true by construction, so
you'd have written `TRUE` in a costume and TLC would pass it.

## The requirements

Seven requirements. Each is a claim about every run of this region, and a
correct model satisfies all seven. They must hold for any box set, any
districts, and any cap. Each one names the TLC keyword it goes under and what
kind of formula it is. None names a subscript.

Where a requirement constrains steps, the subscript is yours to choose. A step
rule is only tested at steps that change what its subscript watches. Watch one
field, and every step that changes only the other fields satisfies the rule
for free. TLC won't warn you. Work out what each rule has to watch.

1. **A sign-off says what it means.** Whenever a district is signed off, every
   box in that district works to the amendment being circulated.

   `INVARIANT`. A claim about a single state.

2. **No box moves ahead of its turn.** At a step where a box comes under
   issue, every district before that box's district in the order is already
   signed off.

   `PROPERTY`. An action property.

3. **One district at a time.** Every box under issue belongs to the district
   in hand, so no box is under issue before the circulation opens or after it
   ends.

   `INVARIANT`. A claim about a single state.

4. **The cap holds on the last district.** At no moment are more than `Cap`
   boxes of the last district under issue.

   `INVARIANT`. A claim about a single state.

5. **A box moves only under issue.** At a step where a box's amendment
   changes, that box was under issue before the step, and its new amendment is
   the one being circulated.

   `PROPERTY`. An action property.

6. **The circulation never goes back.** At a step, no district leaves the
   signed-off list, and the district in hand never falls.

   `PROPERTY`. An action property.

7. **The amendment reaches every box.** Every box ends up working to the
   amendment being circulated, and stays there. Read it that way and not as
   "at some moment it holds", which the opening state already satisfies.

   `PROPERTY`. A claim that something becomes true and then stays true.

### Requirement 7 needs fairness, and fairness needs a target

A formula saying the amendment reaches every box is false over a region that
lets an obliged party stall forever. It should be false there. Rule 9 names
three of them, so your `Spec` has to name them too, with fairness.

Hers is the circulation itself. She has to issue the boxes of the district in
hand and sign that district off. A box under issue has to paste the amendment
in. And the clerk has to keep going round, which is the obligation that
catches people. She reads the board to sign off, so a clerk who neglects one
box forever stalls her as surely as she can stall herself.

Head office carries none of it. Rule 9 leaves the amendment optional, and
fairness on issuing it would oblige a party the rules say owes nothing.

Weak fairness on your whole next-state relation isn't what rule 9 means. It
obliges head office along with the rest, so every run has to issue the
amendment. A circulation that never opens is then a run your model can't
produce. I suspect requirement 7 comes out green over that smaller region
anyway, which is the part that makes blanket fairness hard to catch.

## Two choices this statement leaves open

**What the board carries.** Rule 6 says a line records what the clerk found.
It doesn't say what "what he found" comprises, and rule 7 doesn't say what
guards a sign-off. Those two settle together, and settling them is the work of
this problem. Write down what you chose.

**When a visit lands.** The statement doesn't fix whether the clerk can look
at a box while a district is in hand. It doesn't fix whether one visit covers
one box or several either. The region this came from settles neither, as far
as I can tell. Decide, and say which you decided.

Watch the second one, because I suspect it's where a model shrinks without the
author noticing. The tighter you tie the clerk's round to her steps, the fewer
runs you've checked. All seven can then stay green over a region that no
longer exists.

A model can be wrong in two directions, and only one of them turns a check
red. Allow a step the rules forbid, and a requirement breaks with a trace to
show for it. Forbid a step the rules allow, and every check stays green over a
region nobody runs.

## Checking

Check at three boxes and two districts:

```
Boxes = {b1, b2, b3}
Districts = <<{b1}, {b2, b3}>>
Cap = 1
```

I think two districts is the least that has an order to get wrong. One box in
the first and two in the last is the least that makes the cap bite. It also
leaves the box that can be passed over on its own, in the district that goes
first. `Cap = 1` is as tight as the last district gets.

`Districts` is a sequence of sets of boxes, and a district's number is its
position in it. I think TLC takes that shape in a `.cfg` without complaint. If
yours balks, declare the two sets as separate constants and build the sequence
in your module.

Run TLC with deadlock checking off. The flag is `-deadlock`, and despite its
name it turns the check off. The end of the story is every district signed off
and every box working to the amendment, and your model may well have nothing
enabled there. That stall is the design working, not an error.

No state count is quoted here. The board is your own state, so no two models
agree on a count and a number would only tell you whose model you'd written.
Check two other things instead: all seven come out green, and your model can
still produce a run where head office never issues anything.

## What to deliver

Your module, the `.cfg` you checked it with, and a short note saying what you
settled under each of the two open choices.
