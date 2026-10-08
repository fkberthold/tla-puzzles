# The branch transfer

A friendly society pays sick pay and funeral money to its members out of their
own subscriptions. Members belong to branches, and every branch keeps a roll.
One entry per member, under that branch's own numbering. The roll decides who
pays in and who can draw out, so a member who is off every roll belongs to
nothing.

Members move house, and the society moves them between branches. The secretary
names a set of members and asks the clerk to transfer them from one branch's
roll to another's. One instruction, one answer back. The clerk does the
writing, and nobody else writes on a roll.

A transfer can fail partway through the set, and that's what this problem is
about. The clerk's other two instructions over the same rolls are all or
nothing. This one isn't. Its promises are about each member on her own.

Model this, and establish the three requirements below. The standing orders fix
what happens. How you model it is up to you: your state, your steps, TLA+ or
PlusCal. The one fixed point is the interface, a single operator the checker
reads.

You don't need to know anything about friendly societies. Every rule the clerk
follows is stated here.

## What you get

- This statement: the rules, the interface, and the three requirements.

No model ships. You write it.

## Your task

1. Model the system below, in whatever state shape you like.
2. Define `Observe` over your state, with the three fields the interface fixes.
3. Write each of the three requirements as a formula over `Observe`, and
   declare it in your `.cfg` under the keyword the requirement names.
4. Run TLC at the checking instance. All three must hold.

A model can be wrong in two directions, and only one of them turns a check red.
Allow a step the standing orders forbid, and a requirement breaks with a trace
to show for it. Forbid a step they allow, and every check stays green over a
system that no longer exists. There's a third case worth watching for here. A
requirement can come out true because nothing your model is able to do would
ever break it. TLC reports that the same way it reports a real pass.

## The system

**The parties.**

- **The clerk**, one. She keeps both rolls and she alone writes on them. She
  carries out the instruction and she gives the answer.
- **The secretary**, who issued the instruction before the first moment and
  waits for the answer. She writes on nothing.

Nothing else acts. There's no clock and no calendar, and nothing happens except
by the clerk's own hand.

### Rule 1. The rolls and the entries

Two rolls stand in this system, the **sending** roll and the **receiving** one.
Each numbers its own entries, and the two numberings have nothing to do with
each other. So the question a roll answers about a member is whether it carries
an entry for her, never under what number.

An entry on a roll is in one of two conditions. A **whole** entry carries the
member's particulars and is in force. A **part** entry is one the clerk has
begun and not finished, going on or coming off. It stands on the roll and it
isn't in force, and a member who holds nothing but part entries has no branch.

Either roll may carry entries for members the instruction doesn't name. Those
aren't part of this problem, and the interface doesn't report them.

### Rule 2. The instruction

The secretary has named a set of members, the constant `Members`. She's asked
for every one of them to go from the sending roll to the receiving one. That's
the whole instruction. There's no second one, no amendment, and no withdrawal.

At the start every member in the set holds a whole entry on the sending roll
and no entry at all on the receiving roll.

### Rule 3. What transferring one member means

The clerk transfers a member by entering her on the receiving roll under that
roll's next number and taking her entry off the sending roll. From the
secretary's side it reads as a single act.

The effect on one member is the same as this sequence:

1. Copy the entry onto the receiving roll.
2. Mark the sending roll's entry for striking.
3. Strike it and take it off.

The effect is the same and the semantics are not. The conditions those three
steps would pass through never stand as moments of their own. The clerk never
marks an entry for striking at all.

### Rule 4. The transfer can fail partway through the set

Here's where the transfer differs from the clerk's other two instructions over
the same rolls. She can **copy** a set of members onto a roll, leaving their
entries wherever they already are. She can **enter** a set of members onto a
roll fresh. Both of those are all or nothing. If either fails for any reason,
the roll goes back to the state it was in before the attempt, and no part
result is allowed.

The transfer carries no such promise about the set. What it promises, it
promises about each member on her own, and there are three promises.

- Every member is transferred whole, or left alone.
- No member ends up off both rolls.
- No member ends up on both rolls.

The orders aren't equally firm about the last two. They require the second and
they only ask for the third. A member off both rolls has no branch, pays into
nothing and draws nothing, and a clerk who let that happen would be in breach.
A member on two rolls is counted twice and can draw twice, which the audit
finds and corrects. That's a fault rather than a breach. The clerk here does as
asked on both counts, so all three are checks.

All three hold whatever the clerk reports back, a refusal included.

### Rule 5. The answer

The clerk's answer, when she gives it, is one of two. She reports the
instruction done when every member it named has gone over. Otherwise she
reports it refused. Once given the answer never changes, and after it she
writes nothing further on either roll on account of this instruction.

A refusal is a flat one. It says she didn't carry the instruction out as asked,
and it says nothing about which members she got to.

## The interface

The checker never looks at your state. It evaluates one operator, `Observe`,
which your module defines over whatever state you chose. Each field is a fact
about the rolls right now, the kind the clerk could read off them.

```tla
Observe == [sending |-> ..., receiving |-> ..., answer |-> ...]
```

- **sending**: for each member, the condition of the sending roll's entry.
- **receiving**: for each member, the condition of the receiving roll's entry.
- **answer**: what the secretary has heard back.

The shapes are load-bearing, because the checker compares values. A renamed
field, a fourth field, or a different spelling doesn't fail a check. It keeps
the check from ever running.

- `Observe.sending` and `Observe.receiving` are both functions from `Members` to
  the three conditions, spelled exactly like this:

```
"off"   "part"   "on"
```

- `Observe.answer` is `"waiting"`, `"done"` or `"refused"`.

`"off"` is the condition of a roll that carries no entry for that member. It's a
condition like the other two, not a missing value, so every member carries one
of the three on each roll at every moment.

Behind the operator the state is your own. Keep whatever you like, and let
`Observe` render it as the three facts above.

## The requirements

Three requirements. Each is a claim about every run of this system, and a
correct model satisfies all three. Each one names the TLC keyword it goes under
and what kind of formula it is.

The standing orders say more than these three do. Working out which of their
rules a formula over `Observe` can carry is part of the job.

1. **Nothing stands half-made.** At every moment, neither roll carries a part
   entry for any member. An entry is whole or it isn't there, and there's no
   third condition for it to be caught in.

   `INVARIANT`. A claim about a single state.

2. **Nobody is off both rolls.** At every moment, every member holds a whole
   entry on at least one of the two rolls. Nobody is lost and nobody is left
   without a branch.

   `INVARIANT`. A claim about a single state.

3. **Nobody is on both rolls.** At every moment, no member holds a whole entry
   on both rolls at once. Nobody is carried by two branches.

   `INVARIANT`. A claim about a single state.

### A refusal excuses none of the three

All three hold at every moment of every run, and that takes in every moment
after the clerk has reported the instruction refused. A refusal isn't a reset.
Whatever she had already done to the rolls stands, and the three requirements
are claims about the rolls rather than about the answer.

So none of the three has to mention `Observe.answer`. The field is there
because a run is easier to read with it, not because a requirement needs it.

### Requirements 2 and 3 are separate on purpose

They're close enough to look like one rule with two halves, and joining them
into "exactly one roll" would read tidier than either. Don't. The orders hold
them at different strengths, which is rule 4, and a single formula throws that
away. Each of the three above rules out something the other two allow. Drop any
one and a whole way of getting this wrong goes unchecked.

Requirement 1 has a history worth knowing. An earlier edition of the standing
orders put it as something the clerk should do. The present edition makes it
something she must do. Of the three promises in rule 4, that's the only one
whose strength the revision touched.

## Checking

Check at two members:

```
Members = {m1, m2}
```

Two is the least that shows a member carried over and a member still at her old
branch in the same moment. That's the whole subject of the problem. At one
member there's no partway through the set to fail at.

Run TLC with deadlock checking off. The flag is `-deadlock`, and despite its
name it turns the check off. The answer goes back to the secretary and the
clerk is finished with the instruction. Nothing is enabled there and the system
stops. That stop is the design working, not an error.

## What to deliver

Your module and the `.cfg` you checked it with.
