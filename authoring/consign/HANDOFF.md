# A consignment counter

System description for the reference-solution author (V2-PLAN §9.4). It fixes
the system and leaves the representation open (§3.2). It is not the
learner-facing statement, and nothing in it is worded for a learner.

Sections 1 to 4 are the hand-off: paste them into the §9.4 brief as the
`<system description>`. Sections 5 and 6 are pipeline notes for central. Keep
them out of the author's brief and out of anything downstream of it.

Grid cell: task shape A, in a situation of two independent hands over the same
goods.

## 1. The system

A secondhand shop sells goods on consignment. An owner brings an item in, and
the shop lists it on the floor. From there two hands move independently: the
shop can sell the item to a walk-in buyer, and the owner can take it back
home. Whichever lands first settles the item's future, for good. A sale leaves
the shop owing the owner that item's payout, and when the owner comes to the
till the shop pays out everything it owes them at once.

This description covers one consignment round: each item can be listed once,
and an item taken home stays home for the round. The next round is a new
agreement, and it is out of scope.

**The parties.**

- The **shop**: one counter, one clerk. It lists, sells, sends home, and pays
  out.
- The **owners**, a fixed, finite set. Each owns a fixed set of items. They
  bring items in, take them back, and come to the till.
- **Buyers** are not parties. A sale is the shop's step, and the world
  supplies the buyer.

Nothing coordinates anyone, and nothing in this system must ever happen
(Rule 6). Any party's next step can land between any two steps of another.

### Rule 1. Items and standings

The items are a fixed, finite set, each with one fixed owner. At every moment
each item has exactly one standing:

- **unlisted**: home with its owner, never yet listed.
- **listed**: on the shop floor.
- **returned**: home again unsold, its listing spent.
- **sold**: gone to a buyer, its payout owed to its owner.
- **settled**: sold, and the payout paid.

An item's story runs one way. It starts at home and may take one turn on the
floor. The turn can end back home unsold, or sold with the payout owed until
the till pays it out. Nothing moves backward, ever: a returned item stays
home for the round, and a settled one is done.

### Rule 2. Intake, and the floor

An owner may bring in one of their unlisted items: one step, and the item is
listed. The floor holds at most `Floor` listed items at a time, because the
shop is small. A full floor refuses intake, and there is no waiting list
(simplification): the owner tries again another day.

### Rule 3. Sale

The shop may sell any listed item at any time: one step, the item is sold, and
its payout is owed to its owner from that moment. What the buyer paid, and
what cut the shop keeps, stay outside this system: the payout here is
per-item, owed or paid, never an amount (simplification).

### Rule 4. Going home unsold

While an item is listed, the owner may take it back, and the shop may send it
back to make floor space. Either hand, one step, the same outcome: the item is
returned, its listing spent. The counter's book doesn't record whose hand
carried it out, and this description treats the two as one event.

### Rule 5. The till

When an owner comes to the till and the shop owes them anything, the shop pays
out everything it owes that owner in one motion: every sold item of theirs
settles at once, in that one step. A till visit with nothing owed changes
nothing and is not a step of this system.

### Rule 6. Nobody must act

No step in this system is ever forced. A listed item can hang forever, a
payout can wait forever, an owner can stay home forever. Every obligation here
is about what a step may do, never about a step that must come. The author
should expect no liveness property at all: what must be true below is safety,
all of it, on purpose.

## 2. What must be true

A correct model satisfies all of the following, stated in English over the
observable of section 3 and the constants: the owner set, the item set, the
ownership map, and `Floor`. They must hold for any of them. The instance in
section 4 is one instance, not the specification.

1. **The opening.** Every item is unlisted.
2. **One standing each.** At every moment, every item has exactly one of the
   five standings.
3. **The floor cap.** At every moment, at most `Floor` items are listed.
4. **The lawful path.** An item's standing moves only unlisted to listed,
   listed to returned, listed to sold, or sold to settled. Never any other
   jump, and never backward. A returned or settled item never changes again.
5. **Steps are single, except the till.** A step that changes any item's
   standing either changes exactly one item's standing by a move other than
   sold to settled, or it is a settlement: for exactly one owner, every one of
   that owner's sold items moves to settled together, at least one of them,
   and nothing else moves.

Items 2 and 3 are invariants. Items 4 and 5 constrain steps, so they'll land
as action properties. Item 1 is a condition on the opening state. There is no
liveness item, and Rule 6 is why: its rendering is this list's declared
absence, not a property in it.

Property 5 carries the till whole: "every one of that owner's sold items" is
the wholeness (none left behind), and "exactly one owner" is the grouping (one
owner per visit, nobody else's goods touched).

## 3. The observation operator

The model names an operator, `Observe`, with one field. It is given here as a
named fact, not as syntax. The author renders it over whatever state they
chose.

- **standing**: for each item, its standing right now, one of the five.

One field is thin, and I want to defend the thinness rather than have it read
as an oversight. The ownership map and the item set are constants, so every
question the shop's book answers is standing plus constants. What the shop
owes an owner is their items standing sold. What's on the floor is the items
standing listed, counted for property 3. A separate owed field would be
the shop's internal running total, and the shop's book doesn't publish one:
what it publishes is where each item stands. A model that keeps a payable
ledger beside the standings is welcome to, and a ledger that drifts from the
standings is invisible here, which is the cost of stopping the interface at
the book's own face. I'd rather pay that than expose state the domain doesn't
have.

Event signatures: an intake moves one item from unlisted to listed. A sale
moves one from listed to sold. A going-home moves one from listed to returned.
A settlement moves every sold item of one owner to settled, at least one item,
possibly several at once, and it is the only event that can move more than one
item. Even a one-item settlement shares no signature with a sale: the
endpoints differ. So the action-shaped properties are statable through
`Observe`.

The sufficiency walk, rule by rule. The test in each row is which property
constrains the rule, never which field mentions it. A rule no property
constrains is ungraded, whatever the fields show.

| Rule | Constrained by |
|---|---|
| 1 items and standings | 2 for exactly-one, 4 for the forward path, 1 for the start |
| 2 intake and the floor | 4 for the only way in, 3 for the cap, 5 for one item at a time |
| 3 sale | 4 and 5 |
| 4 going home | 4 and 5 |
| 5 the till | 5 |
| 6 nobody must act | no property, on purpose. The declared all-safety is its rendering, and section 4's quiescence note is its practical face |

Three honest notes on what the interface does not show.

First, whose hand. A going-home step doesn't show whether the owner fetched
the item or the shop sent it back. Rule 4 makes them one event, so a model
with two actions and a model with one produce the same observable behavior,
and that's deliberate.

Second, amounts. No prices, no totals, no shop's cut. The payout is
item-grained, and the standing carries it: sold is owed, settled is paid.

Third, the buyer. A sale's buyer leaves no trace but the standing. Nothing
reads the buyer, so nothing shows one.

## 4. Bounds

**`Floor`** is the shop's own size, not a finiteness device. The item set
already bounds the state.

Suggested instance: 2 owners, 4 items (two each), `Floor` 2.

The instance isn't arbitrary. Two owners make the till's grouping matter: a
settlement has to take one owner's sold items and leave the other's alone.
Four items against a floor of two makes the cap bite: a third intake waits on
a sale or a return. And two items of one owner sold at once is what makes the
pay-everything till distinguishable from a per-item till.

The arithmetic at the instance. Five standings over four items is 625 raw
combinations, and the cap and the forward-only path cut from there. TLC
exhausts this in seconds. That's an estimate. Nobody has run it.

Quiescence: with nobody obliged to act, a behavior can stall anywhere, and one
where every item lands returned or settled has no step left at all. A checker
reporting deadlock there is reporting the design working. That's a config
concern for the reference author, not a modeling one.

