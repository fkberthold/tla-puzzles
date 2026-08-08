# P4: the seed library

A neighborhood seed library lends seed to its members. A member checks out a
packet, plants it, and grows a crop. If the crop comes good, the member saves
seed from it and returns a packet to the library. The packet that comes back is
never the packet that went out (planting consumed that one). What comes back is
new seed of the same variety, one generation on, from the member's own harvest.
The loan is a debt in kind. It's discharged by new goods of the same kind, on a
deadline, not by handing the borrowed thing back.

Everything the problem needs is stated here. Nothing depends on knowing how
seed libraries work.

## The system

Three parties act:

- **Members**: a fixed, finite set.
- **The librarian**: keeps the shelf, the ledger, and the standings.
- **The calendar**: seasons pass on their own.

Nothing coordinates the members. Between two season closes, transactions land
in any order, or not at all. Nothing obliges a member to act, ever. The
calendar is the one party that must act, and it acts alone.

**Stock.** The library holds seed in packets. Every packet holds one variety
and carries a label naming it. The set of varieties is fixed. The librarian
counts packets and reads labels, nothing finer: no weighing, no counting seeds,
no testing what's inside. The opening shelf is the founding donation. Stock
changes only at the desk, by checkout and return. There are no walk-in
donations and no purchases.

**Seasons.** The program runs three growing seasons, one after another, under
its founding grant. At every moment one season is in progress, or the program
has ended. The close of one season is the start of the next, with no gap. A
season in progress eventually closes. The close is nobody's decision and can't
be put off. A close is a step of its own: no transaction lands at the same
moment. The close of the third season ends the program. After it, nothing
further happens. No checkout, no return, no next season.

**Standing.** At every moment each member is in good standing or in default.
Everyone starts in good standing. Standing is the library's record, and it
moves only as the checkout, return, and close rules below say.

**Checkout.** While a season is in progress, a member may check out a packet
of a variety. The librarian allows it only when all three hold:

- the member is in good standing
- at least one packet of that variety is on the shelf
- the member doesn't already owe a return of that variety

The effect is one indivisible step at the desk. One packet of that variety
leaves the shelf with the member, and the ledger gains a debt: this member owes
the library one return of that variety. The librarian handles one transaction
at a time.

The garden is out of sight. Planting consumes the packet for good. If the crop
succeeds, the member can save new seed of the same variety from it. The library
sees none of this. It learns nothing about a loan between checkout and return,
and it can't tell a member whose crop failed from one who just hasn't come in.
Crop failure is real and common. To the library it looks like silence. All
varieties here are annuals, so seed checked out in a season can come back as
new seed within that same season, harvest permitting.

**Return.** While a season is in progress, a member who owes a return of a
variety may return: hand the librarian one packet labeled with that variety.
The librarian takes the packet on the member's word. Nobody checks the
contents, the amount, or whether the seed will germinate. A packet is accepted
only against a debt. A member who owes nothing of that variety has nothing to
return, and the library takes no donations.

Three things happen in one indivisible step. The packet goes on the shelf,
available to anyone from that moment. The debt for that variety comes off the
ledger. And if that cleared the member's last debt while in default, the member
is back in good standing at once. A return counts whether it lands in the
season the debt was made or a later one.

**Close and default.** When a season closes, the librarian squares the book.
Every member who still owes at least one return is in default from that
moment. Every member who owes nothing keeps good standing. The debts themselves
don't move at a close: nothing is forgiven, nothing expires, no fine is added.
A debt stays on the ledger until it's met or the program ends.

Default has one consequence: no checkouts. A member in default can still
return, and clearing the last debt restores standing. There's no other way
back, and no further penalty.

**Simplifications, all deliberate.**

- stock moves only by checkout and return
- all varieties are annuals
- shelf seed stays viable all program
- returns are taken on trust
- membership is fixed
- the library counts packets, nothing finer

The rules above are the whole process.

## What must always hold

Eleven requirements, stated for any member set, any variety set, and any
opening stock.

1. **Standing gates the shelf.** No packet ever leaves the shelf to a member
   in default.
2. **Shelf discipline.** A variety's shelf count never goes below zero. It
   moves one packet at a time: down at a checkout of that variety, up at a
   return of it, never otherwise. A step is one transaction. It moves at most
   one variety's count and at most one member's debt.
3. **Ledger discipline.** A member's debt for a variety appears only at that
   member's checkout of it, and clears only at that member's return of it. A
   return of one variety never touches a debt of another.
4. **One debt per kind.** No member ever owes two returns of the same variety
   at once.
5. **Conservation in kind.** For each variety, at every moment: packets on the
   shelf plus returns owed, summed over the members, equals the opening stock.
6. **A close squares the book.** At the moment a season closes, every member
   owing a return is in default, and every member owing nothing is in good
   standing. Between closes nobody enters default. The one way out of default
   is the return that clears the member's last debt.
7. **Default is never clean.** A member in default owes at least one return.
8. **The reckoning comes.** Each season in progress eventually closes, so the
   program eventually ends. A member who owes a return and never makes one is
   in default when the program ends.
9. **The end is the end.** Once the program has ended, nothing observable
   changes again.
10. **The calendar marches.** The season moves only forward, first to second
    to third to ended, one step at a time, never backwards. At a step where
    the season moves, no shelf count and no debt changes.
11. **The opening.** At the opening the first season is in progress, every
    member is in good standing and owes nothing, and each variety's shelf
    count is its opening stock.

## What a visitor can see

The requirements are read through one named operator, `Observe`. Its fields
are what a visitor could tally without opening a packet or peering over a
garden fence. Each field is a fact about the library as it stands right now.

- **season**: the season now in progress, or the mark that the program ended.
- **shelf**: for each variety, how many packets are on the shelf right now.
- **owed**: for each member and each variety, how many returns of it the
  member owes right now.
- **standing**: for each member, good standing or default, right now.

No packet identities, no generations, no provenance, no contents, no per-debt
age. The library can't see any of those, so no rule and no requirement reads
them.

## The pilot instance

The founding grant fixed four numbers: two members, two varieties (beans and
lettuce), an opening stock of two bean packets and one lettuce packet, and
three seasons. The eleven requirements don't read these numbers. They're the
program's, the same way the three-season horizon is the program's. I think
two members is the least that shows one member's fate leaving the other's
free, and two varieties the least that makes kind-matching bite.

## The submission

A model of this system was submitted for the program's audit. The package is
two files:

- `SeedLibrary.tla`
- `SeedLibrary.cfg`

The config declares thirteen checks: five invariants and eight temporal
properties. TLC 2026.07.31.184830 was run on the package exactly as shipped,
and every check passed.

```
TLC2 Version 2026.07.31.184830 (rev: 30cc360)
Running breadth-first search Model-Checking...
Implied-temporal checking--satisfiability problem has 3 branches.
...
Checking 3 branches of temporal properties for the complete state space
with 270 total distinct states
Model checking completed. No error has been found.
335 states generated, 90 distinct states found, 0 states left on queue.
The depth of the complete state graph search is 7.
```

You can reproduce the run: `tlc -deadlock SeedLibrary.tla` with the config
beside it. The `-deadlock` flag turns TLC's deadlock check off, and the run
above was made that way: the program has a real end state, and stopping there
is the design, not a defect.
The submitter's claim is simple: every declared check passed, so the model is
correct.

## Your task

Audit the claim, not just the model. Answer in writing:

1. What does this green run establish about the submission?
2. What does it fail to establish, and why?

Then make your answer stick, one of two ways.

**A forbidden behavior.** Exhibit a behavior the rules above forbid that the
thirteen checks, run as shipped, cannot reject. Show it step by step and name
the rule it breaks.

**A check of your own.** Write and run a check whose verdict shows something
the shipped run left unexamined. Show the check and its verdict.

A claim without one of those two is an opinion. The audit needs evidence.
