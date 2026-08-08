# The buying club

A modeling problem. Plan on 20 to 40 minutes if you've read the learntla
core chapters.

## The club

A neighborhood buying club orders wholesale food its members couldn't order
alone. The wholesaler takes an order for a product only at a minimum count
of units (below that it isn't worth breaking a case). Members pledge units
in the club's book, and change their minds freely. When the pledges for a
product cover the minimum, the coordinator can place the order. Placement
binds: from that moment each member's standing pledge is their share of the
order, and the book for that product is closed. The goods arrive, and
members collect their shares.

This covers one order cycle: one catalog, each product ordered at most
once. The next cycle is a new book, and it is out of scope.

Three kinds of party act here.

- **Members**: a fixed, finite set. They pledge, revise, withdraw, collect.
- **Coordinator**: keeper of the book. Placing an order is a choice, never forced.
- **Supplier**: acts once per placed product, and carries the one obligation (rule 4).

Nothing obliges a member to do any of it, ever. Nothing coordinates the
members. Revisions land in any order, and any party's next step can land
between any two steps of another.

### Rule 1. The catalog and the book

The catalog fixes the products for the cycle. The book holds one standing
pledge per member per product: a whole number of units, zero meaning none,
and every pledge starts at zero. The club caps any one pledge at `Cap`
units, its own fairness rule (no single household walks off with a
delivery), fixed before the cycle opens. The coordinator keeps one book and
writes one entry at a time.

### Rule 2. Pledging

While a product is open, a member may change their standing pledge for it:
set it to any number from zero through `Cap`, as often as they like, one
product per change. Setting it back to zero is just another change. A
pledge in the book commits nothing yet. That is the whole point of it being
a pledge.

### Rule 3. Placement

The coordinator may place the order for an open product only when the
book's total for that product is at least `Min` at that moment. Placement
is one step, and three things happen in it. The product stops being open,
for good. Each member's standing pledge at that moment becomes their share
of the order (for most members that share is zero, which is fine). And the
order goes to the supplier for the book's total.

Reaching the minimum never forces a placement. A product can sit open above
the minimum forever, and the total can fall back under while it sits: a
member withdraws at the wrong moment, and placement is off the table until
the pledges cover the minimum again. That race is the heart of this system,
and your model must keep it alive. A club where covering the minimum
compels the order, or where pledges freeze once the total covers it, is a
different club.

### Rule 4. Delivery

The supplier delivers a placed order once, whole. Delivery is its own step:
from it, the product's goods are at the club, sorted under members' names
per their shares. A placed order eventually arrives. That's the supply
contract, and it is the one thing in this system that must happen.

### Rule 5. Collection

Once a product has arrived, a member with a share of it may collect: one
step, the whole share, once. There are no partial pickups and no trades at
the table. Goods can sit uncollected forever, and nobody's collection waits
on anybody else's.

### Rule 6. What this system doesn't move

No money: the club settles payment outside the book. No stock: nothing is
ordered for a shelf, and nothing is left over, because the order is the
pledges' sum. No second round: a closed book stays closed.

## What must be true

Nine requirements. Each is a claim about every run of the club, stated over
the observation fields below. They must hold for any finite member set, any
finite product set, any `Min` of at least 1, and any `Cap`. The checking
instance further down is one instance, not the specification.

1. **The opening.** Every product is open, every pledge is zero, every
   share is zero, nothing has arrived.
2. **One hand on the book.** A step that changes the book changes one
   member's pledge on one product, only while that product is open, and
   changes nothing else: no phase and no share moves with it.
3. **The minimum.** A product moves from open to placed only at a step
   where its pledges total at least `Min`.
4. **The snapshot.** At the placing step, each member's share of that
   product becomes their standing pledge at that moment, and every other
   share, of every product, holds still.
5. **Shares move two ways only.** A member's share of a product changes
   only at that product's placement (from zero to the pledge) and at that
   member's collection of it (from the whole positive share to zero, only
   after arrival). Never otherwise. A collection step collects one member's
   share of one product, and changes nothing else.
6. **Phases run forward.** Every product is always open, placed, or
   arrived, and it moves only from open to placed and from placed to
   arrived, one product per step, never backward. At a step where a phase
   moves, no book entry changes, and no share changes beyond what the
   snapshot (4) sets at a placement. A delivery, in particular, moves its
   phase and nothing else.
7. **Shares tell the book's truth.** At every moment, an open product
   carries only zero shares, and a placed or arrived product carries, per
   member, either that member's book entry or zero.
8. **Delivery comes.** Every placed product eventually arrives.
9. **The book is well formed.** At every moment, every member's pledge on
   every product is a whole number from zero through `Cap`.

A model can be wrong in two directions, and only one of them turns a check
red. Allow a step the club forbids, and a requirement breaks with a trace
to show for it. Forbid a step the club allows, and every check stays green
over a club that no longer exists. The traces below are your oracle for the
second direction.

## What grading reads

Your model defines one operator, `Observe`, a record with three fields.
Grading reads `Observe` and nothing else. Your variables never leave your
module: pick whatever state you like, in whatever shape you like, and
render these three facts from it. Each field is the kind of fact a member
could read off the corkboard.

- **phase**: for each product, where it stands.
- **book**: for each member and product, the standing pledge, in units.
- **share**: for each member and product, the units standing under that member's name.

The shapes are fixed, because grading compares values:

- `Observe.phase` is a function from products to `{"open", "placed", "arrived"}`.
- `Observe.book` is a function from members to functions from products to naturals.
- `Observe.share` has the same shape as `Observe.book`.

A share reads zero while its product is open, the bound amount from
placement until that member collects, and zero after.

## Constants and the checking instance

Four constants: `Members`, `Products`, `Min`, `Cap`. `Min` is the
wholesaler's term and is at least one (a zero minimum is no minimum at
all). `Cap` is the club's fairness rule.

Check at 3 members, 2 products, `Min = 3`, `Cap = 2`. At that instance no
member covers an order alone, and one member's withdrawal can race a
placement the other two still cover. TLC should finish in seconds.

## The traces

The `traces/` directory holds one file per requirement. Each file has two
runs, rendered over the observation fields at the checking instance, with
members Ana, Ben, and Cai and products oats and oil. For readability the
trace tables group `book` and `share` by product. That is display only.
The fields themselves keep the shapes above (members first, then products).

- **A run the club can produce.** Your model must allow it.
- **A run that breaks the requirement.** Your model must rule it out.

Each row of a trace is one moment: the value of `Observe`. Consecutive rows
are one step apart. If your model can't produce the first run of every
pair, it's over-constrained, however green your checks are.

## What to deliver

Model the club in PlusCal or TLA+. Define `Observe`. Render the nine
requirements over your model, check them with TLC at the checking instance,
and fix your model until all nine hold and every "run the club can produce"
is a run your model allows. Deliver your module and the `.cfg` you checked
it with.
