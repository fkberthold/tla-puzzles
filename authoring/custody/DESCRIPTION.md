# Shared custody over a planning window

This is the system description a reference-solution author receives (V2-PLAN.md §9.4).
It fixes the system and leaves the representation open (§3.2). It is not the
learner-facing statement, and nothing in it is worded for a learner.

Grid cell: task shape A, in a situation of layered rules and two independent parties.

Real custody arrangements are more complex than this one. Every cut is on purpose. The
load-bearing cuts are named where they land, and gathered again in section 6.

## 1. The system

Two parents share custody of one child under a written arrangement. Call the parents A
and B. The arrangement runs one planning window at a time. This description covers the
life of one window.

**The parties.** The two parents act, and they act independently. Neither waits for the
other. Days begin on their own, without either parent's leave. Either parent's next step
can land between any two steps of the other, and a day can begin between any two steps
of either.

### Rule 1. The window is a fixed run of days

The window covers days 1 through H, for a length H fixed before the window opens. Days
begin one at a time, in order. At the opening, no day has begun. A day, once begun, has
begun for good. Once day H has begun, no rule below permits any further step, and the
window just plays out. The next window is arranged after this one ends, and it is out of
scope.

### Rule 2. Custody is whole days, one parent at a time

On every day of the window, exactly one of the two parents has custody of the child. No
day is shared, no day is split, no day is unassigned. Which parent it is follows from
three sources: the base pattern, the holiday designations, and any swaps the parents
have agreed. Rules 3 through 5 say how the three combine.

Real arrangements carve days at handover times. Here the day is the unit. That is a
simplification made on purpose.

### Rule 3. The base pattern

The arrangement fixes a base pattern before the window opens: each day of the window is
assigned to one parent. The pattern does not change during the window. In practice a
pattern repeats, a week with each parent or similar. For one window it is simply a fixed
assignment of each day to a parent.

### Rule 4. Holiday designations

The arrangement designates some days of the window as holidays. Each designation names
one day and one parent, and is fixed before the window opens. No day carries two
designations.

On a designated day with no agreed swap, custody is with the designation's named parent,
whatever the base pattern says for that day. A designation may name the same parent the
base pattern does. It still stands, it just changes nothing.

Real holiday rules alternate by year and run for multi-day stretches. Here a holiday is
one day with one named parent. That is a simplification made on purpose.

### Rule 5. Swaps, and what a swap does

While the window runs, the parents can agree one-off swaps, one day at a time. A swap
concerns a single day. On a swapped day, custody is with the parent who would not have
it under Rules 3 and 4. That holds on ordinary days and on designated days alike: an
agreed swap reverses whatever the base pattern and the designations settle between them.

### Rule 6. A swap takes a proposal and an acceptance

No swap exists without both parents. One parent proposes the swap of a day. The other
parent accepts it in a separate, later step, or never. Acceptance is what makes the swap
agreed, and nothing compels it.

Either parent can propose the swap of any eligible day: a day they would otherwise have
(offering it) or a day the other would (asking for it). The direction of a swap is fixed
by the day, not by who proposed it.

### Rule 7. What a proposal can name

A proposal names one day. The day must not have begun, and must not already carry an
agreed swap. A parent can have at most one proposal outstanding at a time, and makes no
new one until the outstanding one is resolved. The two parents' outstanding proposals
are independent, and they can name the same day.

### Rule 8. How a proposal is resolved

A pending proposal resolves in exactly one of three ways, and then it is gone.

- **Accepted**: the other parent accepts it, and the swap is thereby agreed.
- **Dropped**: the proposer withdraws it, or the other parent declines it.
- **Voided**: its day begins, or its day comes to carry an agreed swap.

Dropping and voiding have the same effect: the proposal is gone and custody is
untouched. A resolved proposal spends nothing, and the proposer is free to propose
again, the same day included, where Rule 7 still allows it.

Voiding is immediate. The moment the named day begins, or an agreed swap lands on it,
the proposal is void. The second case covers a race: both parents can hold proposals on
the same day, which by Rule 6 are proposals of the same swap. If one is accepted, the
other is void from that same moment.

### Rule 9. Agreed swaps are binding, and capped

An agreed swap stands for the rest of the window. It cannot be undone, and by Rule 7 its
day cannot be proposed again, so each day carries at most one agreed swap, ever.

The arrangement allows at most N agreed swaps per window, for a cap N fixed before the
window opens. Once N swaps are agreed, acceptance is no longer available. Proposing
still is, but such a proposal can only end dropped or voided.

A consequence worth naming: once a day has begun, its custody is settled. No proposal
can name it any more, so no swap can ever touch it again.

## 2. What must be true

A correct model satisfies all of the following. They are stated in English over the
observables of section 3 and the arrangement's constants: the day set 1..H, the base
pattern, the designations, the cap N, and the two parents. They must hold for any H, any
pattern, any designations, and any N. The instance in section 4 is one instance, not the
specification.

One name recurs: a day's **scheduled** parent is the designation's named parent on a
designated day, and the base-pattern parent otherwise. It is definable from the
constants alone.

1. **Totality.** At every moment, every day of the window has exactly one custodian,
   A or B.
2. **The opening baseline.** At the opening, each day's custodian is its scheduled
   parent.
3. **At most one flip.** Over the whole window, a day's custodian changes at most once.
   This carries Rule 9: one swap per day, binding, never reversed.
4. **Flips come from acceptance.** A day's custodian changes only at a step where a
   proposal for that day was outstanding just before and is gone just after. Nothing
   else moves custody: not a drop, not a void, not a day beginning. Which proposals were
   made and dropped along the way leaves no trace in custody.
5. **The past is fixed.** Once a day has begun, its custodian never changes.
6. **Proposals point forward.** An outstanding proposal always names a day that has not
   begun and whose custodian is still its scheduled parent.
7. **The cap.** At every moment, at most N days have a custodian other than their
   scheduled parent.
8. **Quiet at the end.** Once day H has begun, nothing observable changes.

## 3. The observation operator

The model names an operator, `Observe`, with three fields. Each field is an expression
over the model's state. The fields are given here as named facts, not as syntax. The
author renders them over whatever state they chose.

- **today**: the latest day to have begun, or a marker that none has.
- **custodian**: for each day of the window, the parent who has custody of it, as
  things stand now.
- **pending**: for each parent, the day their outstanding proposal names, or a marker
  for none.

Why each field is there:

**today** is what properties 5, 6, and 8 quantify over. Without it the interface has no
before and after, and the past-is-fixed rule is unstateable.

**custodian** carries properties 1, 2, 3, 5, and 7. It is the arrangement's
question-answering behavior: ask the parents, at any moment, who has the child on day
12, and this is their answer. A model that derives the answer and a model that maintains
it both produce this field. That is what keeps it representation-neutral.

**pending** is what makes property 4 causal and property 6 stateable. Without it a
custodian flip has no visible cause at the interface. Its per-parent shape carries Rule
7's one-outstanding rule, which is a rule of the system, not of any representation.

The sufficiency walk, rule by rule:

| Rule | Where it lands at the interface |
|---|---|
| 1 | `today` starts at none, steps through 1..H in order, then holds (property 8) |
| 2 | property 1 |
| 3 | property 2, through the scheduled parent |
| 4 | property 2, through the scheduled parent |
| 5 | properties 3 and 4: a flip is single, and reverses the scheduled assignment |
| 6 | property 4: the flip and the proposal's resolution are one step |
| 7 | property 6, plus the per-parent shape of `pending` |
| 8 | `pending` clears with a flip (accepted) or without one (dropped, voided) |
| 9 | properties 3 and 7 |

Three honest notes on what the interface does not show.

First, who moved. Acceptance is the other parent's act (Rule 6), but a step at the
interface shows a proposal resolving and a day flipping, not whose hand did it. No
property above depends on the actor. The pilot's issuing rule has the same shape: the
city issues, and `issued` just flips.

Second, withdraw against decline. The two are one observable event, which is why Rule 8
states them as one resolution. A model that omits one of the pair produces the same
observable behavior as one that has both.

Third, the agreed swaps themselves. There is no field for the swap set and none for the
count, and that is deliberate. Both are derivable: given property 3, a day carries an
agreed swap when its custodian differs from its scheduled parent. A field exposing a
swap ledger or a rule set would push the model toward one side of the central fork in
section 5, so the interface stays at outcomes.

## 4. Bounds

**H, the window length.** The arrangement runs window by window, and days past H are not
proposable because the next window's pattern and designations are not in force yet (Rule
1). The bound is the process's own edge, not a device for keeping the model finite.
Instance: H = 14, one week with each parent.

**N, the cap on agreed swaps.** Real custody orders do cap ad-hoc rearrangement, or so I
understand, and Rule 9 makes the cap part of the arrangement. Instance: N = 2.

**One outstanding proposal per parent.** Stated as a rule of the arrangement (Rule 7):
resolve one before opening another. I'll be honest that this rule earns its keep twice,
since it also caps the proposal state. Section 6 names the alternative.

**Two parents.** The domain's own number, not a bound.

The arithmetic at the instance. `today` takes at most 15 values (none, then 1..14). Each
parent's pending proposal takes at most 15 (none, or one of 14 days). Agreed-swap
combinations at N = 2 over 14 days number 1 + 14 + 91 = 106. The naive product is
15 x 15 x 15 x 106, about 358,000, and the reachable count sits well under it, since a
pending day must be un-begun and unswapped. I'd expect TLC to clear this in seconds,
which leaves the 60-second budget a wide margin.

A suggested instance for the reference `.cfg`: days 1 through 7 to A, days 8 through 14
to B, designations day 4 to B and day 11 to A (both real overrides), N = 2. Worth one
extra run with an idle designation (named parent equal to the base parent) to make sure
nothing keys off designations always overriding.

## 5. Open forks

These are modeling choices the description leaves open on purpose. The first is the
central one, and it bifurcates the whole spec.

- **State or derived**: custody as a variable the actions maintain, or an operator over
  the agreements.
- **One view or two**: one shared account of the agreements, or two per-parent views
  kept in agreement.
- **The baseline**: designation-over-pattern folded at use, or precomputed into one
  scheduled assignment.
- **The swap record**: a set of days, per-day flags, or nothing but outcomes.
- **Voiding**: a step of its own, or folded into day-beginning and acceptance.
- **The parents**: processes, or bare actions.

Every rule in section 1 and every property in section 2 holds under both sides of each
fork. If a later pass finds one that does not, that is a defect in this description, and
I'd want it reported rather than repaired in place.

## 6. Ambiguities I resolved, and could have resolved otherwise

The pilot's author settled six of these silently and each one surfaced downstream as a
risk. These are mine, with the road not taken.

1. **Precedence.** Swap over designation over pattern. The other order is defensible:
   designations as court-ordered and inviolable, swaps allowed only on ordinary days. I
   chose the total chain because it keeps every day swappable and the layering uniform.
2. **What a swap is.** A single-day reversal. The alternative is a paired exchange (you
   take my day 4, I take your day 11), which preserves each parent's day count and would
   support a balance property. It also squares the proposal space and multiplies the
   edge cases, so I dropped it.
3. **One swap per day.** No toggling. The alternative lets swaps compose, each new
   agreement re-flipping the day. That breaks the custodian-against-scheduled reading in
   section 3 and buys little.
4. **Swaps are irrevocable.** No mutual cancellation. The alternative (a second
   agreement undoes the first) costs the same as 3.
5. **One proposal outstanding per parent.** The alternative is several at once. This is
   the one resolution where the state bound leaned on the choice. The rule is a
   plausible piece of a real arrangement, but I picked it partly for the bound, and I'd
   rather say so here than have it read as pure domain fact.
6. **Void, not block.** A pending proposal whose day begins, or whose day gets swapped
   through the counterpart proposal, is void. The alternatives were that it blocks the
   day from beginning (nothing in the domain supports a day waiting on paperwork) or
   that it stays acceptable on the day itself.
7. **The cap binds acceptance, not proposal.** Proposing at the cap is legal and futile.
   The alternative blocks the proposal too. Either is unambiguous. I picked the one that
   keeps Rule 7 free of the cap.
8. **Designations are window-local.** One day, one named parent, fixed at the opening.
   Year-alternation and multi-day holidays are out of scope, and Rule 4 says so.
9. **Whole days.** No handover times, no split days. Rule 2 says so.
10. **Direction belongs to the day.** Either parent can propose either direction. The
    alternative restricts proposing a day to the parent who does not hold it. That would
    make the proposer's identity load-bearing, and the identity of an actor is invisible
    at the interface (section 3, first note), so the restriction would be ungradable.
