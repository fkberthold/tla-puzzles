# A bonded excise store

System description for the reference-solution author (V2-PLAN §9.4). It fixes the
system and leaves the representation open (§3.2). It is not the learner-facing
statement, and nothing in it is worded for a learner.

Sections 1 to 4 are the hand-off: paste them into the §9.4 brief as the
`<system description>`. Sections 5 and 6 are pipeline notes for central. Keep
them out of the author's brief and out of anything downstream of it.

Grid cell: task shape B, in a situation of business rules with no concurrency
(S9). This is rung 1 of batch 2, load vector 1 2 1 0 0 0, and representation 1
is its single new high over the floor. The system below is meant to be thin.
Rung 1 is the Airlock drill plus a real system to read, and nothing more.

## 1. The system

Excise goods carry a tax called duty. Spirits, tobacco and fuel are the usual
ones. A bonded store is a place the revenue authority has approved, where such
goods can sit with the duty not yet paid. That suspension is what "under bond"
means. This system is one keeper, one store, and the lots in it. Nothing below
needs any customs knowledge that isn't stated here.

**The parties.** One. The **keeper** runs the store, and every step in this
system is his. Nothing else acts. There's no clock, no calendar, and no event
that happens on its own.

### Rule 1. Lots

Goods move as lots. `Lots` is a fixed, finite set, named up front. A lot is
whole. It's never split, never merged with another, and never renamed. At any
moment a lot is in exactly one of four places: not yet entered, in the store
under bond, released for home consumption, or moved on under bond. Every lot
starts not yet entered.

### Rule 2. Entry

The keeper enters a lot into the store. Goods don't arrive on their own, and no
lot enters unless the keeper enters it. On entry the lot is under bond and the
duty on it is unpaid.

### Rule 3. Release for home consumption

The keeper can release a lot that's in the store. Release is the duty point.
The duty on that lot is paid in the same motion, and the lot leaves the store.
There's no way to pay the duty on a lot and keep it in the store, and no way to
release a lot without paying.

### Rule 4. Movement under bond

The keeper can move a lot that's in the store on to another approved store. The
lot leaves and the duty stays unpaid, because the bond carries on at the
receiving store. The receiving store is outside this system. Nothing about it
is modeled, nobody there acts, and a lot moved on is simply gone.

### Rule 5. Two ways out, and no way back

Release and movement under bond are the only ways a lot leaves the store.
There's no loss, no breakage, no write-off, and no way to take a lot back off
the store's account. Once a lot is out it stays out. It never returns to the
store, its place never changes again, and its duty never changes again. Duty
once paid stays paid.

### Rule 6. Nothing has to happen

The keeper acts when he chooses and never on a deadline. He can leave a lot
outside forever, and he can leave a lot in the store forever. Nothing in this
system must eventually happen.

## 2. What must be true

A correct model satisfies all of these. They're stated in English here, over the
observables of section 3. The author renders them as properties of their model.

1. **Duty and place agree.** A lot's duty is paid exactly when that lot has been
   released for home consumption. A lot not yet entered, a lot in the store, and
   a lot moved on under bond all have their duty unpaid.
2. **The only two exits.** When a lot that's in the store changes place, its new
   place is released for home consumption, or moved on under bond.
3. **Leaving is final.** Once a lot is out of the store, released or moved on,
   its place never changes again and its duty never changes again.

Item 1 is a claim about a single state, so it's an invariant. Items 2 and 3 each
compare a lot's record at two consecutive moments, so they constrain steps and
land as action properties. Nothing here needs "eventually", so there's no
liveness and no fairness conjunct to decide.

Each item breaks on a short finite trace, which is what §3.9 needs downstream.
Item 1 falls in a single state, a lot sitting in the store with its duty paid.
Item 2 falls on one step, a lot going from the store back to not yet entered.
Item 3 falls on one step, a released lot turning into a moved-on lot with its
duty going unpaid in the same motion. None of the three needs more than two
states to break, and each one is satisfied by an ordinary run of the system.

Three is the cap, not a target I stopped short of. The reference author adds a
type invariant, and four cfg lines is the top of the rung's property-count band.
I considered a fourth item pinning the opening state (every lot not yet entered,
every duty unpaid) and left it out. The shipped spec's `Init` fixes the opening,
and a fifth line would push the count to the next level and break the rung.

## 3. The observation operator

The operator is named `Observe`. Each field is a fact about the store right now,
the kind the keeper could read off the stock account. The fields are given here
as named facts, not as syntax. The author renders them over whatever state they
chose, one field per line.

**place**: for each lot, where it stands now. Not yet entered, in the store
under bond, released for home consumption, or moved on under bond. All three
must-be-trues read it, and without it none of them can be stated at all.

**dutyPaid**: for each lot, whether the duty on it has been paid. Needed for
must-be-true 1, and for the second clause of 3.

**Why duty is its own field.** This is the one real decision in the operator, so
it gets said plainly. Duty has to be reportable as a fact in its own right, and
never as a reading of `place`. Derive it and must-be-true 1 is true by
construction, the learner writes `TRUE` in a costume, and TLC passes it. So the
shipped spec carries duty as state the keeper's actions set, which means a step
could in principle set duty and place out of step with each other. Must-be-true
1 is what forbids that. The screener flagged this and I'm taking it
(`authoring/bonded-store/reports/step0-screens.md:372-375`).

**Sufficiency walk.** The test in each row is which property constrains the
rule, never which field mentions it. A rule a field names and no property
constrains is ungraded. First, what each must-be-true reads:

| Must-be-true | Reads |
|---|---|
| 1 Duty and place agree | place, dutyPaid |
| 2 The only two exits | place |
| 3 Leaving is final | place, dutyPaid |

Then each rule, against the properties that constrain it:

| Rule | Constrained by |
|---|---|
| 1 Lots | The four-places clause is the type invariant, which is a real cfg line and not a shape argument. The one-place-at-a-time clause rides `place`'s shape: a lot has one place value and there's nowhere to record a second, so no observation can show a lot in two places at once. Whole lots ride the same shape, since `Lots` is fixed and `place` is total over it |
| 2 Entry | 1. A lot the keeper has just entered is in the store, so 1 forces its duty unpaid. The half about who acts is ungraded on purpose, and the next paragraph says why |
| 3 Release | 1, in both directions. Released forces paid, and paid forces released, so neither a free release nor a payment on a stored lot can be observed |
| 4 Movement under bond | 1. Moved on forces the duty unpaid. The receiving store has no observable at all, which is the point of putting it outside |
| 5 Two ways out, no way back | 2 for the exits, 3 for the finality. Duty-once-paid is 3's second clause |
| 6 Nothing has to happen | Nothing, and that's how it's graded. It's the absence of an obligation, and what carries it is that no property here is a liveness one |

Two rules are ungraded above and I'd rather name the reason than let a reader
find it. `Observe` shows the store, not the hands in it. Who took a step is
invisible at this interface, so "the keeper enters the lot" can't be a property
of any model, whatever fields you add. At shape B the spec ships complete, so
the learner reads the actions instead of grading them. Rule 6 is the same shape
from the other end. An obligation would show up as a liveness property, and its
absence is what says there's no obligation.

Everything else is constrained. Every field earns its place through at least one
must-be-true, so nothing in the operator is decoration.

## 4. Bounds

TLC must check the suggested instance exhaustively in well under a second.

- **`Lots`**: the store's own set of lots, not a device for keeping the model
  finite. The config picks one instance and the rules hold for any.
- **The four places** (Rule 1): fixed by the rules, not by the config.
- **Duty as a yes or no** (Rule 3): the system asks whether the duty is paid,
  never how much.

**Suggested instance**: 3 lots. Three is the least that puts a lot in each of
the store's three outcomes at once, one still in the store, one released, one
moved on. That's the state where must-be-true 1 bites in both directions in the
same observation.

The arithmetic. Four places and a duty flag gives 8 records per lot, so 512 in
the type space at three lots. Must-be-true 1 ties the flag to the place, which
cuts each lot to 4 live records, so I make the reachable count about 64. Under
1,000 and sub-second with a lot of room. That's an estimate. Nobody has run it.

**Quiescence.** When every lot has left the store, no action is enabled and the
system stops. That's the intended end of the story, not a fault. A checker
reporting deadlock there is reporting the design working, and the reference
author should handle it in the config rather than by inventing a stuttering
action this system doesn't have.

## 5. Open forks

At shape B the learner writes no state, so the forks here are the reference
author's alone and there are fewer of them than a shape A description carries.
Each line is a choice the rules don't make.

- **Duty**: a flag per lot, or the set of lots duty has been paid on.
- **Place**: a status per lot, or a partition of `Lots` into named sets.
- **The keeper**: one PlusCal process with an `either`, or bare actions.
- **Lot names**: model values, or numbers.

The reading gate is ch11, so the reference ships as PlusCal in the c-syntax
dialect with one process, and the Airlock drill is the shape to write at
(`exercises/ch11/references/Airlock.tla`).

One fork I closed on purpose, and it's the one above in section 3. Duty is its
own state and is never derived from place. That's a real narrowing of the
author's freedom, and I think it's worth the cost, because the alternative
hands the learner a rule that can't be got wrong.

**The dropped candidates.** The screen report offered four candidate rules
(`authoring/bonded-store/reports/step0-screens.md:361-366`). I kept two and cut
two. "Every lot held in the store is under bond" is strictly weaker than
must-be-true 1, which already forces an in-store lot's duty unpaid, so it grades
nothing the kept rule doesn't. "The set of duty-paid lots never shrinks" falls
out of must-be-trues 1 and 3 together: a paid lot is released, a released lot's
record is frozen, so the paid set can't shrink. A redundant cfg line spends one
of four slots and teaches nothing, so both went.

Must-be-true 2 is mine rather than the screener's, and it's there because the
other two leave a hole. A step taking a lot from the store back to not yet
entered satisfies 1 (unpaid on both sides) and never triggers 3 (the lot was
never out). Without 2 the store's account can be quietly erased, which is the
one thing a bonded regime exists to stop.

## 6. Ambiguities resolved, and how they could have gone

1. **Bond expiry.** Doesn't exist here. Real bonds run on a time limit, and a
   limit needs a calendar. A calendar is a step this description assigns to no
   party, which takes step sources from 0 to 3 and breaks the rung outright. The
   screen report flagged the same thing.
2. **The receiving store.** Outside the system, stated in Rule 4. The
   alternative models both ends, which is a second party and a transfer
   protocol. §3.2 obliges the description to fix the system completely, so the
   boundary gets a sentence rather than an implication.
3. **Duty on a stored lot.** Can't happen. Payment and release are one motion.
   The alternative adds a separate payment action and a fifth place, duty paid
   but still stored. That kills must-be-true 1's biconditional, and it's the
   rule carrying most of this rung's weight.
4. **Partial lots.** A lot moves whole. Quantities and splitting would turn
   `place` into a vector and bring arithmetic to a rung that isn't about
   arithmetic.
5. **Re-entry.** A lot that has left never comes back. Returned-goods relief is
   a real thing in customs, and modeling it kills must-be-true 3 and most of the
   system's shape with it.
6. **Deficiency.** No loss, no breakage, no write-off. Real stores account for
   deficiency, and duty usually falls due on it. It's the most tempting addition
   here, and it's a third exit with its own duty rule, which is a fourth
   must-be-true this rung can't carry.
7. **Nothing must happen.** The keeper is under no obligation. An obligation to
   clear the store is liveness, and the rung's property kind stops at action
   properties.
8. **Goods enter by the keeper's act.** Rule 2 says so in as many words. If the
   statement lets goods "arrive", the step belongs to nobody and step sources
   jumps to 3. The screen report named this as one of two boundaries the
   downstream author has to draw.
9. **No money.** Duty is a yes or no. Rates, sums and a running total are the
   obvious extension and they grade nothing this rung is for.
10. **A fixed set of lots.** Every lot is named up front and starts outside. The
    alternative creates lots on entry, which needs an unbounded set and a
    different kind of bound in section 4.
11. **Three overlapping sets.** A model could carry in-store, released and
    moved-on as three sets that overlap. I closed that by making `place` one
    fact per lot instead of three memberships, so the overlap has nowhere to
    live at the interface. The alternative is a fourth must-be-true saying a lot
    is in one place, which spends a slot on something the operator's shape
    already settles.
12. **The word "warehouse".** The real term of art is bonded warehouse. This
    file says store, because `harness/screen.sh:110` carries a `warehouse|robot`
    map row that fires on the bare word and returned a BURNED verdict on a
    domain with no robots in it. The screen report has the one-word probe that
    shows it, and a follow-up to narrow the row. The report cites the row at
    line 112 and `grep -n warehouse harness/screen.sh` puts it at 110, so I've
    used 110 here. Where a downstream author needs the real term, they should
    use it and let the record carry the reason.
