# P1. Shared custody over a planning window

Two parents share custody of one child under a written arrangement. Your job
is to model one planning window of that arrangement in TLA+ or PlusCal, from
scratch, and to show with TLC that your model keeps every promise the
arrangement makes.

Nobody hands you variables, actions, or a state layout. Deciding what a step
is, and what your model has to remember, is the exercise. The rules below fix
what the arrangement does. How your model does it is yours.

## The system

The two parents are A and B. They act independently. Neither waits for the
other, and days begin on their own, without either parent's leave. Any step
of one parent can land between any two steps of the other, and a day can
begin between any two steps of either.

1. **The window.** The window covers days 1 through H, for a length H fixed
   before it opens. Days begin one at a time, in order. At the opening, no
   day has begun. A day, once begun, has begun for good. Once day H has
   begun, nothing more happens in this window. The next window is arranged
   after this one ends, and it is out of scope.

2. **Whole days.** On every day of the window, exactly one parent has custody
   of the child. No day is shared, split, or unassigned. Which parent it is
   follows from three sources: the base pattern, the holiday designations,
   and any swaps the parents have agreed. Rules 3 through 5 say how the three
   combine.

3. **The base pattern.** The arrangement fixes a base pattern before the
   window opens: each day is assigned to one parent. The pattern does not
   change during the window.

4. **Holiday designations.** The arrangement designates some days as
   holidays. Each designation names one day and one parent, and is fixed
   before the window opens. No day carries two designations. On a designated
   day with no agreed swap, custody is with the designation's named parent,
   whatever the base pattern says. A designation may name the same parent the
   base pattern does. It still stands, it just changes nothing.

5. **What a swap does.** While the window runs, the parents can agree one-off
   swaps, one day at a time. On a swapped day, custody is with the parent who
   would not have it under rules 3 and 4. That holds on ordinary days and on
   designated days alike.

6. **A swap takes two.** No swap exists without both parents. One parent
   proposes the swap of a day. The other accepts it in a separate, later
   step, or never. Acceptance is what makes the swap agreed, and nothing
   compels it. Either parent can propose any eligible day: one they would
   otherwise have (offering it) or one the other would (asking for it). The
   direction of the swap is fixed by the day, not by who proposed it.

7. **What a proposal can name.** A proposal names one day. That day must not
   have begun, and must not already carry an agreed swap. A parent has at
   most one proposal outstanding at a time, and makes no new one until the
   outstanding one is resolved. The two parents' outstanding proposals are
   independent, and they can name the same day.

8. **How a proposal ends.** A pending proposal resolves in exactly one of
   three ways, and then it is gone.

   - **Accepted**: the other parent accepts, and the swap is thereby agreed.
   - **Dropped**: the proposer withdraws it, or the other parent declines.
   - **Voided**: its day begins, or its day comes to carry an agreed swap.

   Dropping and voiding leave custody untouched. A resolved proposal spends
   nothing, and the proposer is free to propose again, the same day included,
   where rule 7 still allows it. Voiding is immediate. The moment the named
   day begins, or an agreed swap lands on it, the proposal is void. The
   second case covers a race: both parents can hold proposals on the same
   day, which by rule 6 are proposals of the same swap. If one is accepted,
   the other is void from that same moment.

9. **Agreed swaps are binding, and capped.** An agreed swap stands for the
   rest of the window. It cannot be undone, and by rule 7 its day cannot be
   proposed again, so each day carries at most one agreed swap, ever. The
   arrangement allows at most N agreed swaps per window, for a cap N fixed
   before the window opens. Once N swaps are agreed, acceptance is no longer
   available. Proposing still is, but such a proposal can only end dropped or
   voided.

One name recurs below. A day's **scheduled** parent is the designation's
named parent on a designated day, and the base-pattern parent otherwise. It
is fixed before the window opens, and it never moves.

## The arrangement to check

Model this window and check every property on it.

- **H = 14**: days 1 through 14.
- **Base pattern**: days 1 through 7 to A, days 8 through 14 to B.
- **Designations**: day 4 to B, day 11 to A.
- **N = 2**: at most two agreed swaps.

So the scheduled parents run `AAABAAA BBBABBB`, days 1 through 14. Keep the
rules general. Nothing in your model should depend on the pattern being one
week each, or on the cap being 2, beyond binding these values where TLC
needs numbers.

## The observation interface

Your module must define an operator named `Observe`: a record with exactly
three fields. Grading runs entirely through it. The grader attaches its own
rendering of the properties below to your `Observe` and runs TLC against
your model. If a field has the wrong shape, those checks cannot run at all,
so the shapes here are contractual.

- **today**: the latest day to have begun. The value 0 until day 1 begins,
  then the day's number, 1 through 14.
- **custodian**: a function with domain 1..14. `custodian[d]` answers: if you
  asked the parents right now who has the child on day d, what would they
  say. The answer is a parent value, A or B, for each day.
- **pending**: a function with domain {A, B}. `pending[p]` is the day named
  by parent p's outstanding proposal, 1 through 14, or 0 if p has none.

The parents appear in the observation as the two values A and B. Declare
constants named `A` and `B` in your module and bind them to model values in
your configuration. Days are plain integers, and 0 is the marker for "no day
yet" and "no proposal" alike.

Two deliberate absences. There is no field for who moved. A step shows a
proposal resolving and custody flipping, not whose hand did it. And there is
no field for the agreed swaps themselves, no set and no count. An agreed
swap shows at the interface as exactly one thing: a day whose custodian
differs from its scheduled parent. That fact is worth having when you write
properties 3 and 7.

## What must hold

Establish all ten of these with TLC, rendered over `Observe`. They are the
arrangement's own promises, so they are stated the way the parents would
state them. Deciding what TLA+ form each one takes is your work, not a
given.

1. **Total custody.** At every moment, every day of the window has exactly
   one custodian, A or B.

2. **The opening baseline.** At the opening, each day's custodian is its
   scheduled parent.

3. **At most one flip.** A day's custodian changes at most once over the
   whole window.

4. **Flips come from acceptance.** A day's custodian changes only in a step
   where a proposal naming that day was outstanding just before and is gone
   just after. Nothing else moves custody: not a withdrawal, not a decline,
   not a voiding, not a day beginning.

5. **The past is fixed.** Once a day has begun, its custodian never changes.

6. **Proposals point forward.** An outstanding proposal always names a day
   that has not begun and whose custodian is still its scheduled parent.

7. **The cap.** At every moment, at most N days have a custodian other than
   their scheduled parent.

8. **Quiet at the end.** Once day H has begun, nothing observable changes.

9. **The window runs.** At the opening, no day has begun. The latest begun
   day moves only two ways: from none to day 1, and from day k to day k+1.
   And day H eventually begins.

10. **A proposal holds its day.** A parent's outstanding proposal never
    trades one day for another in a single step. If p has a proposal before
    a step and after it, it names the same day. Naming a new day takes two
    steps: the old proposal resolves, then a fresh one is made.

## Traces

The `traces/` directory beside this file gives, for each property, one
behavior that satisfies it and one that violates it. All of them are written
over the observation fields only, and every violating trace comes from a
real broken model. Read them before you model. If TLC later hands you a
counterexample shaped like one of them, you are standing in that trap.

## Running it

Check everything on the arrangement above. Property 9 ends in an
"eventually", so your TLC run must include the temporal checks, and those
are the slow part. The full check takes 2 to 3 minutes on a fast machine.
Budget minutes, not seconds. A run that sits quiet for two minutes is
working, not hung.


## Deliverables

- Your module (PlusCal or plain TLA+), defining `Observe` as specified.
- Your TLC configuration for the arrangement above.
- All ten properties checked and green, in one run or several.
