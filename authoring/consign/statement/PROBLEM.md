# The consignment counter

A secondhand shop sells goods on consignment. An owner brings an item in, the
shop puts it on the floor, and from there two hands move on their own. The
shop can sell the item to a walk-in buyer. The owner can take it back home.
Whichever lands first decides the item's future for good. A sale leaves the
shop owing the owner that item's payout, and when the owner next comes to the
till, the shop pays out everything it owes them at once.

Model the shop, and establish the five obligations under "What to establish"
below. The rules here fix what the shop does, completely. How you model it is
up to you: your state, your steps, TLA+ or PlusCal. The one fixed point is
the interface, a single operator the checker reads.

## The rules of the round

The model covers one consignment round. Each item can go on the floor at most
once. An item taken home stays home for the round. The next round is a new
agreement, and it's out of scope.

**The parties.** One shop: a single counter, a single clerk. It lists, sells,
sends home, and pays out. A fixed, finite set of owners, each owning a fixed
set of items. Owners bring items in, fetch them back, and come to the till.
Buyers walk in off the street, but they aren't parties: a sale is the shop's
step, and the world supplies the buyer.

**The book.** At every moment each item stands in exactly one of five ways,
and the shop's book shows which:

- **unlisted**: still home, never yet on the floor
- **listed**: on the shop floor now
- **returned**: home again unsold, its one turn spent
- **sold**: bought by a walk-in, payout owed to the owner
- **settled**: payout paid, story over

An item's story runs one way. It starts at home. It may take one turn on the
floor. The turn ends back home unsold, or in a sale, owed until the till
pays. Nothing ever moves backward.

**Intake.** An owner may bring in one of their items that has never been on
the floor. One step, and it's listed. The floor holds at most `Floor` items
at once, because the shop is small. When the floor is full the intake is
refused, and there's no waiting list. The owner tries again another day.

**Sale.** The shop may sell any listed item, at any time. One step, and the
item is sold, its payout owed from that moment. No prices and no shop's cut
appear anywhere in this model. The book tracks whether each item is owed or
paid, never how much.

**Going home unsold.** While an item is on the floor, its owner may fetch it
back, and the shop may send it back to clear space. Either hand, one step,
the same outcome: the item is home, its turn spent. The book doesn't say
whose hand carried it out.

**The till.** When an owner comes to the till and the shop owes them
anything, the shop pays everything it owes that owner in one motion. Every
sold item of theirs settles in that single step. A till visit with nothing
owed changes nothing, and isn't a step of this system.

**Nobody must act.** No step of this system ever has to happen. A listed
item can sit forever. A payout can wait forever. An owner can stay home
forever. Nothing coordinates the parties, and any party's next step can land
between any two steps of another.

## The interface

The checker never looks at your state. It evaluates one operator, `Observe`,
which your module defines over whatever state you chose.

Your module declares four constants, under exactly these names:

- `Owners`: the set of owners
- `Items`: the set of items
- `OwnerOf`: a function in `[Items -> Owners]`, fixed for the round
- `Floor`: a natural number, the floor's capacity

And one operator, with one field:

```tla
Observe == [standing |-> (* your rendering *)]
```

`Observe.standing` must be a function from `Items` to the five standings,
spelled exactly as the book spells them:

```
"unlisted"   "listed"   "returned"   "sold"   "settled"
```

That shape is load-bearing. The checker's obligations read `Observe.standing`
and nothing else of yours. A renamed field, a sixth spelling, or a different
shape doesn't fail the checks, it keeps them from ever running.

Behind the operator, the state is your own. Whatever you keep, `Observe`
translates it into the book's face: where each item stands, right now.

## What to establish

Five obligations, each about what the book may show. A correct model
satisfies all five, and you should be able to say where each one lives in
your spec.

1. **The opening.** At the start of the round, the book shows every item
   unlisted.

2. **One standing each.** At every moment the book gives each item exactly
   one of the five standings. An item the book lost track of, or one carrying
   some sixth standing, must never appear.

3. **The cap.** The book never shows more than `Floor` items listed at once.

4. **One way only.** The book never shows an item change standing except by
   one of the four lawful moves: taken in (unlisted to listed), sold (listed
   to sold), home unsold (listed to returned), paid out (sold to settled).
   No move backward, no skipped stop, no second turn on the floor. A returned
   or settled item never changes again.

5. **Single steps, whole payouts.** A step that changes the book is one of
   two things. Either exactly one item changes standing, by a lawful move
   that isn't a payout. Or it's a settlement: every sold item of exactly one
   owner turns settled in that step, at least one, and nothing else moves.
   In particular, the book never shows a payout in parts. If a step settles
   any item at all, it settles everything the shop owes that item's owner.

That's the whole list, and all five are safety: what the book must never
show. There's no liveness obligation, on purpose. Nobody must act in this
shop, so nothing in it ever has to get anywhere, and a model that adds
fairness to force progress is modeling a different shop.

## Checking

Check against a small instance first: two owners, four items (two each),
`Floor = 2`. That's a few hundred distinct states, and TLC finishes in
seconds, so check early and check often.

Leave deadlock checking off. Nothing must act, so a finished round (every
item home or paid out) has no step left, and TLC would report that stall as
a deadlock. Here it's the design working.

## Traces

The `traces/` directory holds one pair per obligation: a trace that
satisfies it and one that violates it, both rendered as the book (each state
is `Observe.standing`, nothing more). Read a pair to check your reading of
an obligation before you formalize it.
