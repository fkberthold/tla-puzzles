# P1 custody, step 2: the frozen variant matrix

Reference under test: `authoring/custody/reference/Custody.tla`, checked as
`MCCustody.tla` against `MCCustody.cfg` and `MCCustodyIdle.cfg`, merged at
`91821ec`. System description: `authoring/custody/HANDOFF.md`.

V2-PLAN.md §9.5 governs. The verifier authors the variants, the verifier does not
fix anything, and a repairer who did not write the variants works against the set
frozen below.

## The freeze

The 26 variants in the next section were written before the first TLC run of this
step. The set does not move again. Nothing is added when a run comes back
surprising, and nothing is pruned when a variant turns out to be uncatchable.

Each variant is one edit to a copy of `Custody.tla`. Both `.tla` companions
(`MCCustody.tla`) and both `.cfg` files stay byte-identical to the shipped
reference. So a variant that goes red does it against the obligations the author
declared, in the instance the author chose.

Coverage rule I set myself: at least one variant per numbered rule clause in
HANDOFF sections 1 and 2, plus the three difficulty concentrations the step-1
report flagged, plus the observation operator itself. Rule 3 and Rule 4 reach the
observables only through `Scheduled`, so they get a mutation each on that operator
and share a third on the opening state.

## Variant table

| ID | Rule | The mutation | Predicted |
|---|---|---|---|
| V01 | 1 | `Init`: `today = NoDay` becomes `today = 1` | caught, OpeningNoDayBegun |
| V02 | 1 | `BeginDay` steps two days at a time, clearing pending up to the new day | caught, TodayMarches |
| V03 | 1 | new `Unbegin` action moves `today` back one day | caught, TodayMarches |
| V04 | 1 | `BeginDay` guard `today < H` becomes `today <= H` | caught, TypeOK |
| V05 | 1 | `Spec` drops `WF_vars(BeginDay)` | caught, WindowCompletes |
| V06 | 1 | new `EndChurn` action swaps day 1 while `today = H` | caught, QuietAtEnd or PastFixed |
| V07 | 2 | `Custodian` returns `NoDay` on a swapped day | caught, TotalCustody |
| V08 | 3 | `Scheduled` ignores `Base` and returns `A` off a holiday | uncaught, self-consistent |
| V09 | 3, 4 | `Init`: `swapped = {}` becomes `swapped = {1}` | caught, OpeningBaseline |
| V10 | 4 | `Scheduled` ignores `Hol` and returns `Base[d]` | uncaught, self-consistent |
| V11 | 5 | a swapped day goes to `A`, not to the other parent | uncaught |
| V12 | 5 | `Custodian(d) == Scheduled(d)`, so a swap does nothing | uncaught |
| V13 | 6 | new `Unilateral` action agrees a swap with no proposal | caught, FlipCause |
| V14 | 7 | `Propose` guard `d > today` becomes `d >= today` | caught, PendingFresh |
| V15 | 7 | `Propose` drops the `d \notin swapped` guard | caught, PendingFresh |
| V16 | 7 | `Propose` drops the `pending[p] = NoDay` guard | uncaught |
| V17 | 7 | `Propose` forbids a day the other parent already named | uncaught, restriction |
| V18 | 8 | `Drop` agrees the swap, clearing only the proposer's slot, no cap check | caught, CapRespected |
| V19 | 8 | `Drop` agrees the swap under the cap, clearing by named day | uncaught |
| V20 | 8 | `BeginDay` leaves `pending` alone, so a day begins without voiding | caught, PendingFresh |
| V21 | 8 | `Accept` clears only the proposer's slot, losing the same-day race | caught, PendingFresh |
| V22 | 8 | `BeginDay` swaps the day it begins | caught, FlipCause |
| V23 | 9 | new `Unswap` action removes an agreed swap on a day not yet begun | caught, FlipOnce |
| V24 | 9 | `Accept` cap guard `< N` becomes `<= N` | caught, CapRespected |
| V25 | 3 (interface) | `Observe.pending` reports `NoDay` for both parents | caught, FlipCause |
| V26 | 3 (interface) | `Observe.today` reports `NoDay` always | caught, WindowCompletes |

## Exact mutations

Each entry gives the reference text and the replacement, as an exact string swap
against `Custody.tla`.

**V01.** `/\ today = NoDay` in `Init` becomes `/\ today = 1`.

**V02.** In `BeginDay`, `/\ today < H` becomes `/\ today + 2 <= H`,
`/\ today' = today + 1` becomes `/\ today' = today + 2`, and
`IF pending[p] = today + 1` becomes `IF pending[p] <= today + 2`. The third edit
keeps the void rule honest under the skip, so the catch lands on the march and not
on freshness.

**V03.** A new action, added to `Next` as a disjunct:

```
Unbegin ==
    /\ today \in Days
    /\ today' = today - 1
    /\ UNCHANGED <<swapped, pending>>
```

**V04.** In `BeginDay`, `/\ today < H` becomes `/\ today <= H`.

**V05.** `Spec == Init /\ [][Next]_vars /\ WF_vars(BeginDay)` becomes
`Spec == Init /\ [][Next]_vars`.

**V06.** A new action, added to `Next` as a disjunct:

```
EndChurn ==
    /\ today = H
    /\ Cardinality(swapped) < N
    /\ 1 \notin swapped
    /\ swapped' = swapped \cup {1}
    /\ UNCHANGED <<today, pending>>
```

The cap guard is there on purpose. Without it the variant also busts
`CapRespected`, and I want the end-of-window clause to answer for itself.

**V07.** `Custodian(d) == IF d \in swapped THEN Other(Scheduled(d)) ELSE Scheduled(d)`
becomes `Custodian(d) == IF d \in swapped THEN NoDay ELSE Scheduled(d)`.

**V08.** `Scheduled(d) == IF d \in DOMAIN Hol THEN Hol[d] ELSE Base[d]` becomes
`Scheduled(d) == IF d \in DOMAIN Hol THEN Hol[d] ELSE A`.

**V09.** `/\ swapped = {}` in `Init` becomes `/\ swapped = {1}`.

**V10.** `Scheduled(d) == IF d \in DOMAIN Hol THEN Hol[d] ELSE Base[d]` becomes
`Scheduled(d) == Base[d]`.

**V11.** `Custodian(d) == IF d \in swapped THEN Other(Scheduled(d)) ELSE Scheduled(d)`
becomes `Custodian(d) == IF d \in swapped THEN A ELSE Scheduled(d)`.

**V12.** `Custodian(d) == IF d \in swapped THEN Other(Scheduled(d)) ELSE Scheduled(d)`
becomes `Custodian(d) == Scheduled(d)`.

**V13.** A new action, added to `Next` under `\E d \in Days`:

```
Unilateral(d) ==
    /\ d > today
    /\ d \notin swapped
    /\ Cardinality(swapped) < N
    /\ \A q \in Parents : pending[q] # d
    /\ swapped' = swapped \cup {d}
    /\ UNCHANGED <<today, pending>>
```

The last guard keeps a pending proposal off the swapped day, so `PendingFresh`
stays clean and `FlipCause` answers alone.

**V14.** In `Propose`, `/\ d > today` becomes `/\ d >= today`.

**V15.** `/\ d \notin swapped` is deleted from `Propose`.

**V16.** `/\ pending[p] = NoDay` is deleted from `Propose`.

**V17.** `/\ \A q \in Parents : pending[q] # d` is added to `Propose`.

**V18.** `Drop` becomes:

```
Drop(p) ==
    /\ pending[p] # NoDay
    /\ swapped' = swapped \cup {pending[p]}
    /\ pending' = [pending EXCEPT ![p] = NoDay]
    /\ UNCHANGED today
```

**V19.** `Drop` becomes the same thing `Accept` is:

```
Drop(p) ==
    /\ pending[p] # NoDay
    /\ Cardinality(swapped) < N
    /\ swapped' = swapped \cup {pending[p]}
    /\ pending' = [q \in Parents |->
                      IF pending[q] = pending[p] THEN NoDay ELSE pending[q]]
    /\ UNCHANGED today
```

**V20.** In `BeginDay`, the `pending'` conjunct is deleted and
`/\ UNCHANGED swapped` becomes `/\ UNCHANGED <<swapped, pending>>`.

**V21.** In `Accept`, the `pending'` conjunct becomes
`/\ pending' = [pending EXCEPT ![p] = NoDay]`.

**V22.** In `BeginDay`, `/\ UNCHANGED swapped` becomes
`/\ swapped' = IF Cardinality(swapped) < N THEN swapped \cup {today + 1} ELSE swapped`.

**V23.** A new action, added to `Next` under `\E d \in Days`:

```
Unswap(d) ==
    /\ d \in swapped
    /\ d > today
    /\ swapped' = swapped \ {d}
    /\ UNCHANGED <<today, pending>>
```

The `d > today` guard keeps `PastFixed` out of it.

**V24.** In `Accept`, `/\ Cardinality(swapped) < N` becomes
`/\ Cardinality(swapped) <= N`.

**V25.** In `Observe`, `pending |-> pending` becomes
`pending |-> [p \in Parents |-> NoDay]`.

**V26.** In `Observe`, `today |-> today` becomes `today |-> NoDay`.

## Why these clauses, and what I expect to be hard

Rules 1, 2, 6, 7, 8 and 9 all have clauses that move an observable, and I expect
the declared obligations to hold them. The three places I expect trouble are the
three the step-1 report named, plus one it did not.

The report said the interface cannot see the actor, so a drop that flips is
observationally an acceptance. V18 and V19 split that claim in two. V18 is the
careless form, which overruns the cap and clears the wrong slot. V19 is the
careful form, which respects the cap and clears by named day. I expect V18 to go
red and V19 to stay green, because V19 is not an approximation of `Accept`, it is
`Accept`.

The one the report did not name is `Scheduled`. HANDOFF section 3's sufficiency
table says Rules 3 and 4 are constrained by property 2, "through the scheduled
parent". That holds only if `Scheduled` is pinned outside the spec under test.
Here it is an operator in the same module the obligations read, so V08 and V10
move the yardstick and the measurement together. I expect both to pass.

V12 is the `Inv == TRUE` probe §5.5 exists for. Every obligation in the cfg is
safety except `WindowCompletes`, and a spec where acceptance changes nothing
satisfies all of them.

## The reference itself

§9.5 checks 1 through 4 and 6, run before any variant. Every TLC invocation went
through `harness/verdict.sh` from `harness/` as the working directory, at
`-t 300`.

| Check | Command | Token | rc |
|---|---|---|---|
| 1a | `verdict.sh -t 300 -p "Gate!NonVacuous" ../authoring/custody/reference/MCCustody.tla` | `OK` | 0 |
| 1b | the same with `-c ../authoring/custody/reference/MCCustodyIdle.cfg` | `OK` | 0 |
| 2 | the same as 1a without `-p`, plus `-- -inv FALSE` | `SAFETY_VIOLATION` | 12 |

Check 3 rides check 1: `-postCondition "Gate!NonVacuous"` was on both runs, and
rc=0 rather than rc=10 is the postcondition passing.

**Check 4, coverage.** No action has `total == 0` on either instance. The action
lines from `MCCustody.cfg`, in `distinct:total` form:

```
<Init>:     1:1
<BeginDay>: 574:102354
<Propose>:  96320:182420
<Accept>:   5565:29540
<Drop>:     0:182420
```

`Drop`'s zero is in the `distinct` column, which is the trap §9.5 check 4 names
outright. `Drop` fires 182,420 times and discovers nothing new, because every
state a drop reaches is already reachable another way. The predicate is `total`,
and `Drop`'s total is 182,420.

**Check 6, counts.** Both instances: 496,735 states generated, 102,460 distinct,
depth 20. Identical, which is the shape to expect when designations feed a derived
custodian rather than the state. `MCCustody.cfg` finished in 1m37s and
`MCCustodyIdle.cfg` in 2m06s.

The step-1 report's timing discrepancy holds. The handoff expects well under 60
seconds and the run takes about two minutes on this box, so `-t 300` is the budget
for anything downstream.

## Three things about the channel, measured on the way past

None of these is a defect in the reference. They're facts about the log and the
harness that anyone reading these runs needs, and I hit all three by accident.

**TLC names an obligation by operator sometimes and by source location other
times.** V01 gave `Error: Property OpeningNoDayBegun is violated by the initial
state:`. V09 gave `Error: Property line 79, col 36 to line 79, col 70 of module
Custody is violated by the initial state:`. Line 79 is `OpeningBaseline`, whose
body is a `\A` over the days. So a harness that wants the obligation's name off
the log has to resolve a line range for the quantified ones. The exit code is
still the verdict, and this is one more reason not to read the console for one.

**`Gate!NonVacuous` reports false on any run that aborts early.** It fired on V01,
V02 and V09, the three runs that stopped at or near the initial state with fewer
than 4 distinct states behind them. In all three the exit code stayed 13, because
the property violation wins. So a `Postcondition NonVacuous ... is false` line
means nothing on a run that already failed, and the guard is readable only on a
run that reached rc=0.

**`harness/seeded-bugs.sh` cannot consume this problem's catches.** §5.5 defines a
catch as `rc == 12`, and the component's phase 3 and phase 4 both have arms for
only 12 and 0 (`harness/seeded-bugs.sh:658` and `:718`). Everything else goes to
`passthrough`, which aborts the matrix. Eight of this reference's twelve
obligations are `PROPERTIES`, and their channel is rc=13 (bead `tla-94n` already
records the split). So most of the catches below would abort `seeded-bugs.sh`
rather than count. I think that's a harness bead rather than a problem bead, but
it needs filing before Stage 5 runs a batch through the component.

## Results

Every variant ran through `harness/verdict.sh` at `-t 300` with
`-p "Gate!NonVacuous"`, against `MCCustody.cfg` copied byte-identical from the
reference. The "named" column is what TLC wrote in the log, quoted.

| ID | Token | rc | Obligation TLC named | Against prediction |
|---|---|---|---|---|
| V01 | `LIVENESS_VIOLATION` | 13 | `Property OpeningNoDayBegun is violated by the initial state` | as predicted |
| V02 | `LIVENESS_VIOLATION` | 13 | `Action property TodayMarches is violated` | as predicted |
| V03 | `LIVENESS_VIOLATION` | 13 | `Action property TodayMarches is violated` | as predicted |
| V04 | `SAFETY_VIOLATION` | 12 | `Invariant TypeOK is violated` | as predicted |
| V05 | `LIVENESS_VIOLATION` | 13 | `Temporal property WindowCompletes was violated` | as predicted |
| V06 | `LIVENESS_VIOLATION` | 13 | `Action property FlipCause is violated` | caught, other obligation |
| V07 | `SAFETY_VIOLATION` | 12 | `Invariant TotalCustody is violated` | as predicted |
| V08 | `OK` | 0 | none | uncaught, as predicted |
| V09 | `LIVENESS_VIOLATION` | 13 | `Property line 79 ... of module Custody` (`OpeningBaseline`) | as predicted |
| V10 | `OK` | 0 | none | uncaught, as predicted |
| V11 | `OK` | 0 | none | uncaught, as predicted |
| V12 | `OK` | 0 | none | uncaught, as predicted |
| V13 | `LIVENESS_VIOLATION` | 13 | `Action property FlipCause is violated` | as predicted |
| V14 | `SAFETY_VIOLATION` | 12 | `Invariant PendingFresh is violated` | as predicted |
| V15 | `SAFETY_VIOLATION` | 12 | `Invariant PendingFresh is violated` | as predicted |
| V16 | `TIMEOUT` then `OK` | 124 then 0 | none | uncaught, as predicted (see below) |
| V17 | `OK` | 0 | none | uncaught, as predicted |
| V18 | `SAFETY_VIOLATION` | 12 | `Invariant PendingFresh is violated` | caught, other obligation |
| V19 | `OK` | 0 | none | uncaught, as predicted |
| V20 | `SAFETY_VIOLATION` | 12 | `Invariant PendingFresh is violated` | as predicted |
| V21 | `SAFETY_VIOLATION` | 12 | `Invariant PendingFresh is violated` | as predicted |
| V22 | `LIVENESS_VIOLATION` | 13 | `Action property FlipCause is violated` | as predicted |
| V23 | `LIVENESS_VIOLATION` | 13 | `Action property FlipOnce is violated` | as predicted |
| V24 | `SAFETY_VIOLATION` | 12 | `Invariant CapRespected is violated` | as predicted |
| V25 | `LIVENESS_VIOLATION` | 13 | `Action property FlipCause is violated` | as predicted |
| V26 | `LIVENESS_VIOLATION` | 13 | `Temporal property WindowCompletes was violated` | as predicted |

**19 caught, 7 uncaught.** Of the caught, 8 came back rc=12 on an invariant and 11
came back rc=13 on a property. V16 needed a second run to get an answer at all,
below.

State counts are worth reading beside the verdicts. V08, V10, V11 and V12 each
generated 496,735 states and found 102,460 distinct, the reference's own numbers.
V19 found the same 102,460 distinct off 343,855 generated, so it has the
reference's reachable states and fewer edges. V17 found 92,800 distinct off
445,495, so it loses states as well as edges. Those three shapes are the three
uncaught classes, visible before any obligation is consulted.

### The second shipped cfg

A variant caught on one instance is caught, so the open question for
`MCCustodyIdle.cfg` is only whether the idle-designation instance catches
something the first one missed. All seven uncaught variants were re-run against
it, unchanged.

| ID | Token | rc | Generated | Distinct |
|---|---|---|---|---|
| V08 | `OK` | 0 | 496,735 | 102,460 |
| V10 | `OK` | 0 | 496,735 | 102,460 |
| V11 | `OK` | 0 | 496,735 | 102,460 |
| V12 | `OK` | 0 | 496,735 | 102,460 |
| V16 | `OK` | 0 | 2,207,955 | 102,460 |
| V17 | `OK` | 0 | 445,495 | 92,800 |
| V19 | `OK` | 0 | 343,855 | 102,460 |

Every number matches the first instance to the digit. The handoff suggested the
idle-designation run to make sure nothing keys off designations always overriding,
and on this variant set it separates nothing. I'd keep the cfg, since it costs one
line and it answers a question somebody will ask, but it does no work as a
detector here.

### V16 needed a bigger budget than this problem's reference does

V16 came back `TIMEOUT` rc=124 at `-t 300`, which is a fact about the budget and
not an answer about the obligations. Dropping `pending[p] = NoDay` from `Propose`
lets a parent propose from any state rather than only from the no-proposal state,
and that multiplies edges without adding states.

Re-run at `-t 2400`, unchanged in every other way:

```
verdict.sh -t 2400 -c ../tmp-variants/v16/MCCustody.cfg -p "Gate!NonVacuous" \
    ../tmp-variants/v16/MCCustody.tla
```

`OK`, rc=0, 2,207,955 states generated, 102,460 distinct, finished in 6m55s. So
V16 is uncaught, and its distinct count is the reference's while its generated
count is 4.4 times larger. Same reachable states, many more edges, exactly the
shape the mutation predicts.

Two things follow for anyone budgeting downstream runs. A variant can cost several
times what the reference costs, so a per-run budget sized off the reference will
report `TIMEOUT` on a healthy variant. And `TIMEOUT` must never be folded into
"uncaught", because rc=124 is the harness saying it does not know.

## The uncaught variants, and where each fix lives

§9.5 forbids me from repairing anything, so this section says what a repair should
add and where it belongs. The measurement is the repairer's (§9.5b), against the
matrix frozen above.

The uncaught variants fall into three classes, and the classes matter more than
the count. Only one of them is a hole in the obligation set.

### Class 1: the yardstick moves with the model (V08, V10)

`Scheduled` is an operator in `Custody.tla`, and every obligation that mentions
the schedule reads that same operator. `OpeningBaseline`, `PendingFresh` and
`CapRespected` all compare something against `Scheduled(d)`. Change `Scheduled`
and you change both sides of the comparison at once.

The state counts say it cleanly. V08 and V10 both generate 496,735 states and
102,460 distinct, the reference's own numbers to the digit. That's not a
coincidence, it's the mechanism: `today`, `swapped` and `pending` never touch
`Scheduled`, so the reachable state graph is untouched and only the derived
`Observe.custodian` moves. The mutation is invisible to the state space and
invisible to the obligations, in that order.

So Rules 3 and 4 are ungraded as things stand. HANDOFF section 3's sufficiency
table says both are "constrained by property 2, through the scheduled parent",
and I think that reading holds only if `Scheduled` is pinned outside the artifact
under test. Here it isn't.

**Where the fix lives: the harness and the statement, not the obligations.** No
formula over `Observe` can catch this, because `Observe` doesn't expose the
schedule and no obligation reaches the constants except through `Scheduled`. Two
ways out, and I'd take the first:

1. Pin the schedule in a module the learner doesn't write. `MCCustody.tla` already
   holds `MCBase` and `MCHol`, so a `Scheduled` defined there and read by the
   obligations would make a learner's own schedule operator answer to it.
2. Add a fourth `Observe` field for the schedule. That works, and it costs the
   representation-neutrality HANDOFF section 3 argues for, so I'd avoid it.

This is a step-4 and harness item under §6's rule that a red gate names where the
fix lives. Sending it back to the reference author would not close it.

### Class 2: the spec does less, and safety cannot see that (V11, V12, V17, V19)

Eleven of the twelve obligations are safety. `WindowCompletes` is the only
liveness one, and it says nothing about swaps. A variant that only removes
behavior therefore cannot go red, whatever it removes.

V17 and V19 are the honest form of this. Both are strict restrictions of the
reference's transition relation. V17 forbids a proposal on a day the other parent
already named, which Rule 7 allows. V19 turns `Drop` into a second copy of
`Accept`, which loses Rule 8's no-flip resolution entirely. Neither adds a
behavior, so neither can violate a safety obligation. That is correct behavior
from the obligation set, not a hole, and §5.2's grading engine owns it through the
`Φ => ψⱼ` not-too-strong direction.

V11 and V12 are the same shape with a sharper edge. V12 makes acceptance change
nothing at all, and it passes every obligation in the cfg. That's the `Inv == TRUE`
failure §5.5 exists to catch, and the obligation set alone does not catch it. V11
is the partial version: a swap sends the day to `A` whatever the schedule says, so
days scheduled to `B` still flip and days scheduled to `A` never do.

**Where the fix lives: added must-fail witness probes (§5.3), not a strengthened
obligation.** You cannot write "a swap must be able to take effect" as a TLA+
property, because possibility isn't expressible in linear temporal logic over a
spec. Adding fairness to `Accept` would express it and would also misstate the
system, since Rule 6 says nothing compels acceptance. So the check has to be a
second TLC run whose invariant is required to FAIL, which is the pattern the
step-1 report already used by hand for its cap probe. Two probes, not one:

- `Cardinality({d \in Days : Observe.custodian[d] # Scheduled(d)}) < N` must exit
  rc=12. Kills V12.
- `\A d \in Days : Scheduled(d) = A => Observe.custodian[d] = A` must exit rc=12,
  and its mirror for `B`. Kills V11.

The first alone does not kill V11, because V11 still reaches two flipped days. The
direction of the flip is what needs a witness, one per parent.

### Class 3: a real hole in the obligation set (V16)

V16 drops `pending[p] = NoDay` from `Propose`, so a parent can replace an
outstanding proposal in one step without resolving it. That adds behavior rather
than removing it, and no obligation catches it.

HANDOFF section 3 predicted this in its own table: Rule 7's one-outstanding clause
"rides `pending`'s per-parent type, not a property". The type carries at most one
proposal per parent per state. It does not carry Rule 8's claim that a pending
proposal leaves only by being accepted, dropped or voided.

**Where the fix lives: a strengthened obligation, in `Custody.tla` and
`MCCustody.cfg`.** This is the one uncaught variant a repairer can close the
normal way. A candidate to start from:

```
OneOutstanding ==
    [][\A p \in Parents :
          /\ Observe.pending[p] # NoDay
          /\ Observe'.pending[p] # NoDay
          => Observe'.pending[p] = Observe.pending[p]]_Observe
```

A parent's proposal can't move to a different day without passing through the
no-proposal marker. Under V16 `Propose` moves it straight across, so the variant
should go rc=13. Under the reference every non-marker value starts from the
marker, and `Accept`, `Drop` and `BeginDay` only write the marker, so I'd expect
the reference to stay green. The measurement is §9.5b's, not mine.

## What the step-1 report's three flags turned into

The reference author flagged three difficulty concentrations. All three now have
numbers against them.

**Voiding immediacy holds up.** The author folded voiding into `BeginDay` and
`Accept` rather than giving it its own action, and predicted the spec "breaks
visibly" when a variant unfolds it. V20 unfolds the day-begin half and V21 unfolds
the same-day-race half. Both go rc=12 on `PendingFresh`, at 58 and 1,003 generated
states. The fold is graded, and cheaply.

**The drop-that-flips is caught, but not by the cap.** The author expected it
"will only be caught if it busts the cap or the freshness invariant". V18 is the
careless form and it went rc=12 on `PendingFresh`, not on `CapRespected`. The
same-day race breaks four states before the cap does: a drop that adds the day to
`swapped` while clearing only the proposer's slot leaves the other parent pending
on a day that no longer matches its schedule. So the freshness half of the
author's disjunction is what does the work, and it does it early.

V19 is the careful form, and it is uncaught. That's the right answer rather than a
gap. A drop that respects the cap and clears by named day is `Accept`, so the
variant has lost Rule 8's no-flip resolution rather than gained a bad one. It is a
restriction, and it belongs to §5.2's not-too-strong direction. The author's flag
was correct and its consequence is milder than it sounds.

**The opening-condition channel is live and it names its obligation twice
differently.** V01 and V09 both exit 13 off a bare state predicate under
`PROPERTIES`, which corroborates the step-1 probe on this build. The log names
`OpeningNoDayBegun` and does not name `OpeningBaseline`, for the reason in the
channel notes above.

## Two obligations never answered for anything

`PastFixed` and `QuietAtEnd` are not the named catcher on any of the 26 variants.
That isn't a defect I can pin on the reference, and I want to be careful about how
far to push it, but I think both are implied by the rest at this instance.

`PastFixed` says a begun day's custodian never changes. A change needs a proposal
resolving on that day (`FlipCause`), and `PendingFresh` already forbids a proposal
naming a day that has begun. So any behavior `PastFixed` would catch trips one of
those two first, which is what V06 shows: an action that swaps day 1 at `today = H`
went to `FlipCause`.

`QuietAtEnd` says nothing observable changes after day H begins. At `today = H`,
`today` can only move by breaking `TodayMarches` or `TypeOK`, any custodian change
lands on a begun day, and any non-marker pending value breaks `PendingFresh`
because no day is greater than H. So the clause has no room of its own left.

I'd read that as a finding for step 4 and for §5.2 rather than for the repairer.
Per-conjunct partial credit weights twelve obligations equally, and two of them
carry no independent weight on this instance. A learner who omits either still
satisfies the other ten and their spec is no weaker for it.

## Gate verdict: RED, with three arrows

§6 says a red gate names where the fix lives and central dispatches the repair
there, rather than reflexively one step back. Six of the seven uncaught variants
do not point at §9.5b at all, so the arrows are worth keeping apart.

**Arrow 1, to the repairer (§9.5b): V16.** One obligation-level repair, the
`OneOutstanding` candidate above. This is the only uncaught variant a property
change closes, and it is the only thing on the frozen set I'd hand a repairer.

**Arrow 2, to the harness and step 4: V08 and V10.** Rules 3 and 4 are ungraded
because `Scheduled` is defined in the artifact under test and read by the
obligations. Pin it in `MCCustody.tla` or wherever the learner does not write, and
both variants go red for free. A repairer who tries to close this with a property
will not manage it, and should not try.

**Arrow 3, to §5.3: V11 and V12.** The obligation set has one liveness formula and
it says nothing about swaps, so a spec where acceptance changes nothing satisfies
everything. Two must-fail witness probes close it, and they are runs rather than
obligations. V12 is the `Inv == TRUE` failure §5.5 exists to stop, which is why I
call the gate red rather than closing it on a named cause.

**Not an arrow: V17 and V19.** Both are strict restrictions of the reference.
Safety obligations cannot refute a spec that does less, which is correct behavior
rather than a gap, and §5.2's not-too-strong direction owns them. Nothing to
repair.

The reference itself is sound. It passes checks 1 through 4 on both shipped
instances, every action fires, the state space is non-empty, and 19 of 26 seeded
variants go red against it. What's red is coverage of three rules and one vacuity
vector, not correctness of what's there.

Rules 3 and 4 are ungraded outright. Rule 7's one-outstanding clause is ungraded.
Rule 5 is graded in one half and not the other, and the split is worth stating
carefully: given `TotalCustody`, two parents and `OpeningBaseline`, any change to
a day's custodian has to be a reversal, so the "reverses" half rides the
structure. What no obligation says is that an agreed swap has to change anything
at all, which is what V11 and V12 walk through. Rules 1, 2, 6, 8 and 9 each have
at least one variant that goes red.

## Claim provenance

Every verdict, token, exit code and state count above is quoted from a run through
`harness/verdict.sh` on TLC 2026.07.31.184830. The variant files and per-run logs
lived in a scratch directory that was deleted before the commit, so the exact
mutations section is what reproduces them. Each mutated `Custody.tla` was checked
by `diff` against the reference before the first run, and all 26 diffs matched the
table.

Two claims carry no run behind them and are marked as such:

- The `OneOutstanding` candidate is INFERRED. I wrote it and reasoned about it, and
  §9.5 says the measurement belongs to §9.5b.
- The `PastFixed` and `QuietAtEnd` redundancy argument is INFERRED. What I measured
  is that neither was ever the named catcher on 26 variants. The implication
  argument is mine, and I'd want it checked before anyone drops a conjunct.

# RESULTS-2B: the repair, and the re-run against the frozen matrix

Appended by the §9.5b repairer (V2-PLAN.md §6 step 2b, bead `tla-jjo7`). Nothing
above this line changed. The matrix is the one frozen at `f476527`, and all 26
variants below were rebuilt from the "Exact mutations" section by a script that
asserts each anchor matched exactly once. A mutation that quietly did nothing
would make a green run meaningless, so the builder refuses a no-op.

I did not author the variants. Base commit for this work is `99eac6a`.

## What changed

Three edits, one per arrow. None of them touches `Observe`.

**Arrow 1, V16.** `OneOutstanding` is new in `Custody.tla` and new under
`PROPERTIES` in both cfgs. It's the report's own candidate, reparenthesized:

```tla
OneOutstanding ==
    [][\A p \in Parents :
          (/\ Observe.pending[p] # NoDay
           /\ Observe'.pending[p] # NoDay)
              => Observe'.pending[p] = Observe.pending[p]]_Observe
```

The parentheses are mine. Written as a bare junction list with `=>` in the
bullet column, the parse depends on the alignment rule rather than on anything a
reader can see, and I'd rather not have a grading obligation rest on that.

**Arrow 2, V08 and V10.** `Custody.tla` gains a declared constant operator,
`Sched(_)`, and the four obligations that used to read the schedule off
`Scheduled` now read it off `Sched`. Those are `OpeningBaseline`, `FlipOnce`,
`PendingFresh` and `CapRespected`. `MCCustody.tla` gains `MCSched` and
`MCSchedIdle`, and each cfg binds `Sched` to the one matching its `Hol`.

`Scheduled` stays exactly where it was, and `Custodian` still reads it. That
matters twice. It keeps V08 and V10 constructible as the frozen matrix words
them, and it's what makes the catch work at all: the model derives custody from
its own operator while the obligations measure against the instance's, so a
rewrite of `Scheduled` moves one side of the comparison and not the other.

The cfg route I did not take is worth naming, because it looks like the obvious
one. A definition override, `Scheduled <- MCSched` in the CONSTANTS section,
replaces the operator everywhere it appears, `Custodian` included. That doesn't
catch V08, it erases it. The variant would then be the reference.

There's also a new `ASSUME \A d \in 1..H : Sched(d) \in {A, B}`, so a cfg that
binds `Sched` to something that isn't a schedule fails loudly at rc=10 instead
of grading against nonsense.

**Arrow 3, V11 and V12.** Three probe modules under
`authoring/custody/reference/probes/`, each a must-fail invariant with its own
cfg. `CapReachable`, `FlipAwayFromA`, `FlipAwayFromB`. Details below.

## Arrow 1: V16 now goes red in 62 states

```
harness/verdict.sh -t 2400 -c ../tmp-variants/v16/MCCustody.cfg \
    -p "Gate!NonVacuous" ../tmp-variants/v16/MCCustody.tla
```

`LIVENESS_VIOLATION`, rc=13, `Error: Action property OneOutstanding is
violated.` 62 states generated, 58 distinct, depth 3.

Step 2 needed `-t 2400` and 6m55s to get `OK` out of this variant. The catch
lands at depth 3, so the budget note in that section is now a fact about the
uncaught V16 rather than about this one. I ran it at `-t 2400` anyway, since the
budget is what the brief specified and a smaller one proves less.

`OneOutstanding` is the named catcher on exactly one of the 26. That's the
minimality claim, measured rather than argued: it adds nothing to the other 25
verdicts, and every obligation the step-2 run named is still the one named now.

## Arrow 2: the yardstick stopped moving

| ID | Token | rc | Named |
|---|---|---|---|
| V08 | `SAFETY_VIOLATION` | 12 | `Invariant CapRespected is violated by the initial state` |
| V10 | `LIVENESS_VIOLATION` | 13 | `Property line 80, col 36 to line 80, col 66 of module Custody` |

Both were `OK` rc=0 at step 2, on 496,735 generated and 102,460 distinct. Both
now die on the initial state, before a single step.

They die differently, and the difference is arithmetic rather than luck. V08
sends every non-holiday day to A, so six days sit off the pinned schedule at the
opening and the cap of 2 breaks first. V10 ignores the designations, which moves
days 4 and 11 and nothing else, so the count is exactly 2 and `CapRespected`
holds. `OpeningBaseline` is what catches it.

Line 80 is `OpeningBaseline`, and columns 36 to 66 are its quantified body. This
is the naming quirk the channel notes above already recorded, still behaving the
same way. The line moved from 79 to 80 because the new `ASSUME` pushed it down
one.

## Arrow 3: four required probe runs, and four more worth having

Every probe is an invariant the reference has to break. rc=12 is the pass and
rc=0 is the failure, which inverts the usual reading and is why each module
carries a header line saying so.

The four the brief asked for:

| Probe | Tree | Token | rc | Named |
|---|---|---|---|---|
| `CapReachable` | reference | `SAFETY_VIOLATION` | 12 | `Invariant CapNotReached is violated` |
| `CapReachable` | V12 | `OK` | 0 | none |
| `FlipAwayFromA` | reference | `SAFETY_VIOLATION` | 12 | `Invariant AKeepsEveryScheduledDay is violated` |
| `FlipAwayFromA` | V12 | `OK` | 0 | none |

`FlipAwayFromB` is the mirror the report asked for, and I ran it on both trees
too. Reference: rc=12, `Invariant BKeepsEveryScheduledDay is violated`, 110
states. V12: rc=0.

Then V11, which is where the mirror earns its keep:

| Probe | Token | rc | Generated | Distinct |
|---|---|---|---|---|
| `CapReachable` | `SAFETY_VIOLATION` | 12 | 5,738 | 2,373 |
| `FlipAwayFromB` | `SAFETY_VIOLATION` | 12 | 110 | 103 |
| `FlipAwayFromA` | `OK` | 0 | 496,735 | 102,460 |

The report predicted this split and it holds. V11 sends every swapped day to A,
so the B days still move and two of them still differ from the schedule. Both of
those probes fire and neither one has found anything wrong. `FlipAwayFromA` is
the only one that goes silent, and one probe per direction is what it takes.

Read the rc=0 rows next to their state counts. Every one of them explored
496,735 states and found 102,460 distinct, which are the reference's own
numbers. So the space is healthy and the witness is unreachable inside it. That
pair is the deadness signature, and neither half says it alone.

The probes compare against `Sched` rather than `Scheduled`, for the same reason
the obligations do.

## The re-run: §9.5 checks 1 through 6

The gate. Same harness, same working directory, `-t 2400` on every variant so a
budget can't be mistaken for a verdict.

| Check | Command | Token | rc |
|---|---|---|---|
| 1a | `verdict.sh -t 480 -p "Gate!NonVacuous" ../authoring/custody/reference/MCCustody.tla` | `OK` | 0 |
| 1b | the same with `-c ../authoring/custody/reference/MCCustodyIdle.cfg` | `OK` | 0 |
| 2 | the same as 1a without `-p`, plus `-- -inv FALSE` | `SAFETY_VIOLATION` | 12 |

Check 3 rides checks 1a and 1b. `-postCondition "Gate!NonVacuous"` was on both,
and rc=0 rather than rc=10 is the postcondition passing.

**Check 4, coverage.** No action has `total == 0` on either instance, and the
lines are identical to step 2's to the digit:

```
<Init>:     1:1
<BeginDay>: 574:102354
<Propose>:  96320:182420
<Accept>:   5565:29540
<Drop>:     0:182420
```

`Drop`'s zero is still in the `distinct` column, which is still not the
predicate.

**Check 6, counts.** Both instances: 496,735 states generated, 102,460 distinct,
depth 20. Step 2 reported the same three numbers, so the repair moved nothing.
`MCCustody.cfg` finished in 2m19s and `MCCustodyIdle.cfg` in 3m01s, against
1m37s and 2m06s at step 2. I'd read that as the cost of one more temporal
obligation plus whatever else was on the box, not as a change in the search.

**Check 5, the 26 variants.**

| ID | Token | rc | Obligation TLC named | Against step 2 |
|---|---|---|---|---|
| V01 | `LIVENESS_VIOLATION` | 13 | `Property OpeningNoDayBegun is violated by the initial state` | unchanged |
| V02 | `LIVENESS_VIOLATION` | 13 | `Action property TodayMarches is violated` | unchanged |
| V03 | `LIVENESS_VIOLATION` | 13 | `Action property TodayMarches is violated` | unchanged |
| V04 | `SAFETY_VIOLATION` | 12 | `Invariant TypeOK is violated` | unchanged |
| V05 | `LIVENESS_VIOLATION` | 13 | `Temporal property WindowCompletes was violated` | unchanged |
| V06 | `LIVENESS_VIOLATION` | 13 | `Action property FlipCause is violated` | unchanged |
| V07 | `SAFETY_VIOLATION` | 12 | `Invariant TotalCustody is violated` | unchanged |
| V08 | `SAFETY_VIOLATION` | 12 | `Invariant CapRespected is violated by the initial state` | **newly caught** |
| V09 | `LIVENESS_VIOLATION` | 13 | `Property line 80 ... of module Custody` (`OpeningBaseline`) | unchanged |
| V10 | `LIVENESS_VIOLATION` | 13 | `Property line 80 ... of module Custody` (`OpeningBaseline`) | **newly caught** |
| V11 | `OK` | 0 | none | uncaught, probe covers |
| V12 | `OK` | 0 | none | uncaught, probes cover |
| V13 | `LIVENESS_VIOLATION` | 13 | `Action property FlipCause is violated` | unchanged |
| V14 | `SAFETY_VIOLATION` | 12 | `Invariant PendingFresh is violated` | unchanged |
| V15 | `SAFETY_VIOLATION` | 12 | `Invariant PendingFresh is violated` | unchanged |
| V16 | `LIVENESS_VIOLATION` | 13 | `Action property OneOutstanding is violated` | **newly caught** |
| V17 | `OK` | 0 | none | uncaught, named cause |
| V18 | `SAFETY_VIOLATION` | 12 | `Invariant PendingFresh is violated` | unchanged |
| V19 | `OK` | 0 | none | uncaught, named cause |
| V20 | `SAFETY_VIOLATION` | 12 | `Invariant PendingFresh is violated` | unchanged |
| V21 | `SAFETY_VIOLATION` | 12 | `Invariant PendingFresh is violated` | unchanged |
| V22 | `LIVENESS_VIOLATION` | 13 | `Action property FlipCause is violated` | unchanged |
| V23 | `LIVENESS_VIOLATION` | 13 | `Action property FlipOnce is violated` | unchanged |
| V24 | `SAFETY_VIOLATION` | 12 | `Invariant CapRespected is violated` | unchanged |
| V25 | `LIVENESS_VIOLATION` | 13 | `Action property FlipCause is violated` | unchanged |
| V26 | `LIVENESS_VIOLATION` | 13 | `Temporal property WindowCompletes was violated` | unchanged |

**22 caught, 4 uncaught.** Step 2 caught 19. Of the caught, 10 come back rc=12
on an invariant and 12 come back rc=13 on a property.

**No regressions.** All 19 variants caught at step 2 are still caught, and each
one is caught by the same obligation TLC named then. V09's line number moved by
one and its obligation did not. Nothing that was red went green, and no run came
back `TIMEOUT`.

### The four remaining, on both cfgs

| ID | Token | rc | Generated | Distinct | Depth |
|---|---|---|---|---|---|
| V11 | `OK` | 0 | 496,735 | 102,460 | 20 |
| V12 | `OK` | 0 | 496,735 | 102,460 | 20 |
| V17 | `OK` | 0 | 445,495 | 92,800 | 19 |
| V19 | `OK` | 0 | 343,855 | 102,460 | 20 |

`MCCustodyIdle.cfg` returns the same six numbers per row. Every count matches
step 2 to the digit, which I'd take as corroboration that the repair changed the
obligations and not the search.

The idle-designation instance still separates nothing on this variant set. Step
2's reading of it holds.

### Why these four stay uncaught

Two of them were never an arrow. V17 and V19 are strict restrictions of the
reference, and no safety obligation can refute a spec that does less. §5.2's
not-too-strong direction owns them, and adding an obligation to catch them would
be the bend §9.5b forbids.

V11 and V12 are covered, but not by an obligation, and I want to be careful
about the difference. Possibility isn't expressible as a property over a spec.
Fairness on `Accept` would express it and would also misstate Rule 6, which says
nothing compels acceptance. So the check is a second run whose invariant is
required to fail, and the probes above are that run. The 26-variant table reads
`OK` on both rows because the obligation set is doing what it correctly can, and
the probe table is where those two are answered.

That leaves the count at 22 obligations plus 2 probes plus 2 named causes.

## Claim provenance

Every token, exit code, state count and quoted obligation above came out of a
run through `harness/verdict.sh` on TLC 2026.07.31.184830, in this worktree,
during this work. The reference's checks 1a and 1b were re-run at the end and
both came back `OK` rc=0 on the counts recorded here.

The variant trees, the per-run logs and the builder live in a scratch directory
that isn't committed. The builder rebuilds all 26 from the frozen "Exact
mutations" section and fails loudly if an anchor stops matching, so the
committed reference plus that section is what reproduces this.

One claim carries no run behind it and is marked as such:

- The timing comparison against step 2 is INFERRED as to cause. What I measured
  is 2m19s against 1m37s. Attributing the gap to the extra obligation rather
  than to load on the box is a guess, and a cheap one to check if it matters.
