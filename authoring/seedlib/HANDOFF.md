# Seed library checkout with return obligations

System description for the reference-solution author (V2-PLAN §9.4). Task shape A,
model from prose.

Sections 1 to 4 are the hand-off: paste them into the §9.4 brief as the
`<system description>`. Sections 5 and 6 are pipeline notes for central. Keep them out
of the author's brief and out of anything downstream of it.

## 1. The system

A neighborhood seed library lends seed to its members. A member checks out a packet,
plants it, and grows a crop. If the crop comes good, the member saves seed from it and
returns a packet to the library. The packet that comes back is never the packet that
went out. Planting consumed that one. What comes back is new seed of the same variety,
one generation on, from the member's own harvest. The loan is a debt in kind: it's
discharged by new goods of the same kind, on a deadline, not by handing the borrowed
thing back.

Real seed-saving practice is messier than this. Where the description simplifies it,
the text says so at the spot, and the list at the end of this section collects the
simplifications. Everything the model needs is stated here. Nothing depends on knowing
how seed libraries work.

**The parties.**

- The **members**, a fixed, finite set.
- The **librarian**, who keeps the shelf, the ledger, and the standings.
- The **calendar**. Seasons pass on their own.

Nothing coordinates the members. Between two season closes, transactions land in any
order, or not at all. Nothing obliges a member to act, ever. The calendar is the one
party that must act, and it acts alone.

### Rule 1. Stock is packets of named varieties

The library holds seed in packets. Every packet holds seed of one variety and carries
a label naming it. The set of varieties is fixed. The librarian counts packets and
reads labels. The library never weighs seed, never counts individual seeds, and never
tests what's inside a packet. Each packet is a physical object with its own history,
grown by a particular gardener in a particular year, but the librarian goes by the
label.

The opening shelf is the founding donation, given in section 4. Stock changes only at
the desk, by checkout and return. Real libraries also take walk-in donations. This one
doesn't (simplification).

### Rule 2. The program runs three seasons

The library runs as a pilot under its founding grant: three growing seasons, one after
another. At every moment one season is in progress, or the program has ended. The close
of one season is the start of the next. There's no gap between them.

A season in progress eventually closes. The close isn't anyone's decision and can't be
put off. A close is a step of its own: no transaction lands at the same moment. The
close of the third season ends the program. After it, nothing further happens. No
checkout, no return, no next season.

The three-season horizon is part of the program the library runs. It isn't a device
for keeping the model finite.

### Rule 3. Standing

At every moment each member is in good standing or in default. Everyone starts in good
standing. Standing is the library's record. It moves only as Rules 5 and 6 say.

### Rule 4. Checkout

While a season is in progress, a member may check out a packet of a variety. The
librarian allows it only when all three hold:

- the member is in good standing
- at least one packet of that variety is on the shelf
- the member doesn't currently owe a return of that variety

The effect is one indivisible step at the desk. One packet of that variety leaves the
shelf with the member, and the ledger gains a debt: this member owes the library one
return of that variety. The librarian handles one transaction at a time.

**The garden is out of sight.** The member plants the borrowed seed, and planting
consumes the packet for good. If the crop succeeds, the member can save new seed of
the same variety from it. The library sees none of this. It learns nothing about a
loan between checkout and return, and it can't tell a member whose crop failed from
one who just hasn't come in. Crop failure is real and common. To the library it looks
like silence.

All varieties here are annuals: seed checked out in a season can come back as new seed
within that same season, harvest permitting. Real collections hold biennials that need
two years. This one doesn't (simplification).

### Rule 5. Return

While a season is in progress, a member who owes a return of a variety may return:
hand the librarian one packet labeled with that variety. The librarian takes the
packet on the member's word. Nobody checks the contents, the amount, or whether the
seed will germinate. Real libraries spot-check returns. This one doesn't
(simplification).

The librarian accepts a packet only against a debt. A member who owes nothing of that
variety has nothing to return, and the library takes no donations.

Three things happen in one indivisible step. The packet goes on the shelf, available
to anyone from that moment. The debt for that variety comes off the ledger. And if
that cleared the member's last debt while in default, the member is back in good
standing at once.

A return counts whether it lands in the season the debt was made or a later one.
Rule 6 is what makes lateness cost.

### Rule 6. Close and default

When a season closes, the librarian squares the book. Every member who still owes at
least one return is in default from that moment. Every member who owes nothing keeps
good standing. The debts themselves don't move at a close. Nothing is forgiven,
nothing expires, no fine is added. A debt stays on the ledger until it's met or the
program ends.

Default has one consequence: no checkouts (Rule 4). A member in default can still
return, and clearing the last debt restores standing (Rule 5). There's no other way
back, and no further penalty.

### Simplifications, collected

- no donations, no purchases: stock moves only by checkout and return
- all varieties are annuals, so same-season return is possible
- shelf seed doesn't age: every packet stays viable all program
- returns are taken on trust: no inspection, no testing, no weighing
- membership is fixed: nobody joins or leaves
- the library counts packets, nothing finer than a packet

Each departs from real practice on purpose. The rules above are the whole process.

## 2. What must be true

A correct model satisfies all of these, read through the observation in section 3.
They're stated for any member set, any variety set, and any opening stock. All three
are constants of the program, the opening stock included, and the properties read
them directly. The instance in section 4 is one instance, not the specification.

1. **Standing gates the shelf.** No packet ever leaves the shelf to a member in
   default.
2. **Shelf discipline.** A variety's shelf count never goes below zero. It moves one
   packet at a time: down at a checkout of that variety, up at a return of it, never
   otherwise. A step is one transaction: it moves at most one variety's shelf count
   and at most one member's debt.
3. **Ledger discipline.** A member's debt for a variety appears only at that member's
   checkout of it, and clears only at that member's return of it. A return of one
   variety never touches a debt of another.
4. **One debt per kind.** No member ever owes two returns of the same variety at once.
5. **Conservation in kind.** For each variety, at every moment: packets on the shelf
   plus returns owed, summed over the members, equals the opening stock. No object
   survives the loop (the borrowed packet is planted, the returned one is new), but
   the count does.
6. **A close squares the book.** At the moment a season closes, every member owing a
   return is in default, and every member owing nothing is in good standing. Between
   closes nobody enters default, and the one way out of default is the return that
   clears the member's last debt.
7. **Default is never clean.** A member in default owes at least one return.
8. **The reckoning comes.** Each season in progress eventually closes, so the program
   eventually ends. A member who owes a return and never makes one is in default when
   it does.
9. **The end is the end.** Once the program has ended, nothing observable changes
   again.
10. **The calendar marches.** The season moves only forward, first to second to
    third to ended, one step at a time, never backwards. At a step where the season
    moves, no shelf count and no debt changes.
11. **The opening.** At the opening the first season is in progress. Every member is
    in good standing and owes nothing, and each variety's shelf count is its opening
    stock.

Items 4, 5, and 7 are invariants, and so is item 2's floor. Items 1, 3, 6, 9, and 10
constrain steps, so they'll land as action properties, and item 2's other clauses
land with them. Item 8 is the one liveness obligation in this description. Item 11 is
a condition on the opening state.

## 3. The observation

Grading reads the system through one named operator, `Observe`. Its fields are what a
visitor could tally without opening a packet or peering over a garden fence: the
calendar, the shelf census, the ledger, and the standings board. Each field is a fact
about the current state and changes as the state does. No field says how a model
stores anything.

**season**: the season now in progress (first, second, or third), or the mark that
the program has ended. Every deadline fact (properties 6, 8, 9) hangs on season
boundaries, and the calendar's own march (10) is read here. With no boundary in
view, no deadline is gradable.

**shelf**: for each variety, how many packets are on the shelf right now. The
checkout guard, shelf discipline (2), conservation (5), and the close's stillness
(10) all read it. A yes/no of
availability can't carry property 5. In a correct model this count follows from the
ledger, but grading has to see the models where it doesn't.

**owed**: for each member and each variety, how many returns of it the member owes
right now. Properties 3 through 8 read it, and 10 reads it at a close. It's a count, not a yes/no, on purpose:
property 4 says the count never passes one, and an interface that can't show two
can't show the violation.

**standing**: for each member, good standing or default, right now. Properties 1, 6,
7, and 8 read it. It's not recoverable from the other fields at a single moment,
since a debt in hand doesn't say whether a close has passed over it.

**What the operator leaves out.** No packet identities, no generations, no
provenance, no contents, no per-debt age. The library can't see any of those (Rules
1, 4, and 5), so no rule and no property reads them. Age of a debt needs no field: a
defaulted member's debts are all past-season and a good-standing member's are all
current-season (default blocks checkout, so no new debt lands on a defaulted member,
and clearing every debt is the only way back). Standing already carries what age
would.

**Every rule is visible.** Each event has its own signature through the fields. A
checkout shows as one variety's shelf count down one and one member's owed count up
one, in the same step. A return shows as the reverse. A close shows as the season
moving on while every shelf count and every debt holds still, which is Rule 2's
own-step clause and property 10's demand. No two events share a signature, so the
action-shaped properties (2, 3, 6, and 10) are statable through `Observe`, and so
are the guards behind 1 and 4.

| property | fields it reads |
|---|---|
| 1 standing gates the shelf | standing, shelf, owed |
| 2 shelf discipline | shelf, owed |
| 3 ledger discipline | owed, shelf |
| 4 one debt per kind | owed |
| 5 conservation in kind | shelf, owed |
| 6 a close squares the book | season, standing, owed |
| 7 default is never clean | standing, owed |
| 8 the reckoning comes | season, standing, owed |
| 9 the end is the end | all four |
| 10 the calendar marches | season, shelf, owed |
| 11 the opening | season, shelf, owed, standing |

The sufficiency walk, rule by rule. The test is which property constrains the rule,
not which field mentions it. A rule no property constrains is ungraded, whatever the
fields mention.

| rule | constrained by |
|---|---|
| 1 stock and the desk | 2 and 5: one packet at a time, and only checkout and return move it. 11 pins the opening shelf |
| 2 the calendar | 10 for order and the own-step clause, 11 for the start, 8 for the close that must come, 9 for the end |
| 3 standing | 6 and 7, with 11 for where everyone starts |
| 4 checkout | 1, 2, 3, 4, and 5, with 2's one-transaction clause |
| 5 return | 2, 3, 5, and the way back in 6 |
| 6 close and default | 6, 7, and 8 |

Rule 2's order and own-step clauses hang on property 10 alone. Without it they'd
have a field and no property, which is the ungraded-rule shape the test above exists
to catch.

This section fixes the fields and their meaning, not their syntax. The author renders
the operator over whatever state they chose.

## 4. Bounds

The checked instance:

- **members**: two
- **varieties**: two, beans and lettuce
- **opening stock**: two packets of beans, one of lettuce
- **seasons**: three, then the program ends

The founding grant fixed all four. A pilot of two households, seeded with the
donation the founder had, run for three seasons and then audited. The properties in
section 2 don't read these numbers. The numbers are the program's, the same way the
horizon in Rule 2 is the program's.

The instance isn't arbitrary. Two members is the least that shows one member's
default leaving the other free, and contention at the shelf. Two varieties is the
least that gives kind-matching (properties 3 and 4) anything to bite. The uneven
stock does real work: lettuce at one packet makes an empty shelf reachable for a
member who owes nothing of it, and beans at two keeps that count out of yes/no range,
so property 5 doesn't degenerate. Three seasons is the least horizon that holds every
fate of a loan: met in season, lapsed at a close, redeemed late, borrowed again,
lapsed to the end.

I'd put the reachable states under two thousand. Conservation ties the shelf to the
ledger, the season takes four values counting the end, and each member ranges over
seven standing-and-debt combinations. TLC should exhaust that in seconds with
liveness on. That's an estimate, not a measurement. Nobody has run it.

