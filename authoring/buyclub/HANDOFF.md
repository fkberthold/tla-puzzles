# A buying club's group orders

System description for the reference-solution author (V2-PLAN §9.4). It fixes
the system and leaves the representation open (§3.2). It is not the
learner-facing statement, and nothing in it is worded for a learner.

Sections 1 to 4 are the hand-off: paste them into the §9.4 brief as the
`<system description>`. Sections 5 and 6 are pipeline notes for central. Keep
them out of the author's brief and out of anything downstream of it.

Grid cell: task shape A, in a situation of collective commitment under free
revision.

## 1. The system

A neighborhood buying club orders wholesale food its members couldn't order
alone. The wholesaler takes an order for a product only at a minimum count of
units (below that it isn't worth breaking a case). Members pledge units in the
club's book, and change their minds freely. When the pledges for a product
cover the minimum, the coordinator can place the order. Placement binds: from
that moment each member's standing pledge is their share of the order, and the
book for that product is closed. The goods arrive, and members collect their
shares.

This description covers one order cycle: one catalog, each product ordered at
most once. The next cycle is a new book, and it is out of scope.

**The parties.**

- The **members**, a fixed, finite set. They pledge, revise, withdraw, and
  collect. Nothing obliges a member to do any of it, ever.
- The **coordinator**, keeper of the book. Placing an order is the
  coordinator's choice, never forced.
- The **supplier**. It acts once per placed product, and it is the one party
  with an obligation (Rule 4).

Nothing coordinates the members. Revisions land in any order, and any party's
next step can land between any two steps of another.

### Rule 1. The catalog and the book

The catalog fixes the products for the cycle. The book holds one standing
pledge per member per product: a whole number of units, zero meaning none, and
every pledge starts at zero. The club caps any one pledge at `Cap` units, its
own fairness rule (no single household walks off with a delivery), fixed
before the cycle opens. The coordinator keeps one book and writes one entry at
a time.

### Rule 2. Pledging

While a product is open, a member may change their standing pledge for it: set
it to any number from zero through `Cap`, as often as they like, one product
per change. Setting it back to zero is just another change. A pledge in the
book commits nothing yet. That is the whole point of it being a pledge.

### Rule 3. Placement

The coordinator may place the order for an open product only when the book's
total for that product is at least `Min` at that moment. Placement is one
step, and three things happen in it. The product stops being open, for good.
Each member's standing pledge at that moment becomes their share of the order
(for most members that share is zero, which is fine). And the order goes to
the supplier for the book's total.

Reaching the minimum never forces a placement. A product can sit open above
the minimum forever, and the total can fall back under while it sits: a member
withdraws at the wrong moment, and placement is off the table until the
pledges cover the minimum again. That race is the heart of this system.

### Rule 4. Delivery

The supplier delivers a placed order once, whole. Delivery is its own step:
from it, the product's goods are at the club, sorted under members' names per
their shares. A placed order eventually arrives. That's the supply contract,
and it is the one thing in this system that must happen.

### Rule 5. Collection

Once a product has arrived, a member with a share of it may collect: one step,
the whole share, once. There are no partial pickups and no trades at the table
(simplification). Goods can sit uncollected forever, and nobody's collection
waits on anybody else's.

### Rule 6. What this system doesn't move

No money: the club settles payment outside the book (simplification). No
stock: nothing is ordered for a shelf, and nothing is left over, because the
order is exactly the pledges' sum. No second round: a closed book stays
closed.

## 2. What must be true

A correct model satisfies all of the following, stated in English over the
observables of section 3 and the constants: the member set, the product set,
`Min`, and `Cap`. They must hold for any of them. The instance in section 4 is
one instance, not the specification.

1. **The opening.** Every product is open, every pledge is zero, every share
   is zero, nothing has arrived.
2. **The book moves one hand at a time.** A step that changes the book changes
   one member's pledge on one product, only while that product is open, and
   changes nothing else: no phase and no share moves with it.
3. **The threshold.** A product is placed only at a step where its pledges
   total at least `Min`.
4. **The snapshot.** At a placement step, each member's share of that product
   becomes exactly their standing pledge on that product at that moment, and
   every other share, of every product, holds still.
5. **Shares move two ways only.** A member's share of a product changes only
   at that product's placement (from zero to the pledge) and at that member's
   collection of it (from the whole share to zero, only after arrival, only
   from a positive share). Never otherwise. A collection step collects one
   member's share of one product, and changes nothing else.
6. **Phases run forward, each move its own step.** Every product is open,
   placed, or arrived, and it moves only from open to placed and from placed
   to arrived, one product per step, never backward. At a step where a phase
   moves, no book entry changes, and no share changes beyond what the
   snapshot (4) sets at a placement. A delivery, in particular, moves its
   phase and nothing else.
7. **Shares tell the book's truth.** At every moment, an open product carries
   only zero shares, and a placed or arrived product carries, per member,
   either that member's book entry or zero.
8. **Delivery comes.** Every placed product eventually arrives.
9. **The book is well formed.** At every moment, every member's pledge on
   every product is a whole number from zero through `Cap`.

Items 7 and 9 are invariants, and so is 6's three-phase range. Items 2 through
6 otherwise constrain steps, so they'll land as action properties. Item 8 is
the one liveness obligation in this description. Item 1 is a condition on the
opening state.

One interaction worth naming: 7 compares shares against book entries, and that
comparison only means something because 2 closes the book at placement. If the
book could move afterward, 7 would measure against a moving target. The two
properties carry Rule 3's freeze together.

## 3. The observation operator

The model names an operator, `Observe`, with three fields. Each field is a
fact about the club at the current moment, the kind a member could read off
the corkboard. Named facts, not syntax. The author renders them over whatever
state they chose.

- **phase**: for each product, whether it is open, placed, or arrived.
- **book**: for each member and product, the standing pledge.
- **share**: for each member and product, the units standing under that
  member's name: zero while the product is open, the bound amount from
  placement until collected, zero after.

Why each field is there:

**phase** is what gates everything. Properties 2, 5, and 6 quantify over it,
and 8 is stated on it alone. Without it, open and placed are
indistinguishable and the freeze is unstateable.

**book** is what the members say. Properties 2, 3, 4, and 7 read it. It stays
readable after placement because 7 compares against it for the rest of the
product's story.

**share** is what the club owes. In a correct model it's the frozen book entry
until collection, and grading has to see the models where it isn't. It's also
what makes collection visible: at a collection the book holds still and the
share moves.

Event signatures: a pledge change moves one book entry while phases and shares
hold still. A placement moves one phase from open to placed and jumps that
product's shares to the book, while the book holds still. A delivery moves one
phase from placed to arrived and nothing else. A collection moves one share to
zero while book and phases hold still. No two events share a signature, so the
action-shaped properties are statable through `Observe`.

The sufficiency walk, rule by rule. The test in each row is which property
constrains the rule, never which field mentions it. A rule no property
constrains is ungraded, whatever the fields show.

| Rule | Constrained by |
|---|---|
| 1 the catalog and the book | 2 for one-hand-at-a-time, 1 for the all-zero start, and 9 for the `Cap` ceiling |
| 2 pledging | 2, with 7 keeping shares out of it while the product is open |
| 3 placement | 3, 4, and 6, with 2's only-while-open clause closing the book. The never-forces clause is carried by no property, and can't be: it's a permission. Its rendering is item 8 standing alone as this description's only liveness obligation, so a model that compels placement at the minimum satisfies every property here and is caught, if at all, as an over-constrained submission rather than a violated one |
| 4 delivery | 6 and 8 |
| 5 collection | 5, with 7 tying the amount to the frozen book |
| 6 nothing else moves | 2's nothing-else, 4's hold-still clause, 5's never-otherwise, 6's own-step clauses |

Three honest notes on what the interface does not show.

First, hands. A pledge change shows whose row moved. A placement and a
delivery show no hand at all, and no property depends on the coordinator or
the supplier as actors.

Second, the ordered total. No field carries it. It's the book's total at the
placement step, derivable where it matters, and a field for it would push the
model toward a stored-order representation.

Third, money, the truck, and the table. Out of scope by Rule 6. Nothing reads
them, so nothing shows them.

## 4. Bounds

**`Min`** is the supplier's own term and **`Cap`** is the club's own fairness
rule. Both are facts of the system first, and `Min` is at least one: a zero
minimum is no minimum at all. I'll be honest that `Cap` earns its keep twice,
since it also bounds the book.

Suggested instance: 3 members, 2 products, `Min` 3, `Cap` 2.

The instance isn't arbitrary. `Cap` 2 under `Min` 3 means no member covers an
order alone: every placement takes at least two pledgers, so the threshold is
about the club and not about one enthusiast. Three members is the least where
a third member's withdrawal can race a placement the other two still cover.
Two products is the least that shows independent lifecycles interleaving in
one book.

The arithmetic at the instance. Per product the book column has 27 states, the
phase 3, and each share is either zero or its frozen entry. Naive product per
product is a few hundred, so two products give order tens of thousands, and
the reachable count sits under that. TLC should exhaust this in well under a
minute with liveness on (property 8 carries the one eventually). That's an
estimate. Nobody has run it.

