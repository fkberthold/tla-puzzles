# BuyClub reference: state alternatives

Author-only note (V2-PLAN §9.4). It records the state representations I
considered for the buying club and why each lost to the one standing in
`reference/BuyClub.tla`. Blind agents must never see this file.

## What stands

Three variables, one per observable. `phase` maps each product to one of
`"open"`, `"placed"`, `"arrived"`. `book` and `share` map member to product to
a unit count. `Observe` is the identity packaging: three fields, no
translation. I wanted the graded interface and the moving state to be the same
values, so a mismatch can only come from a property, never from a rendering
step.

## A stored order total

The obvious fourth variable: what the club ordered, per placed product. I
dropped it because it never carries information the book doesn't. Placement
closes the book on that product, so the total stays derivable for the rest of
the product's story. Storing it buys one lookup and costs a variable plus a
coupling invariant tying it to the book forever.

## One record per product

A single function from products to a record holding that product's phase, book
column, and share column. It reads well for a per-product lifecycle, and the
interleaving comes out the same. It lost on the properties: one-hand-at-a-time
and the snapshot quantify over members and products separately, and every
`EXCEPT` digs two levels before it touches a number. Same state space, worse
sentences.

## A collected flag

Keep `share` frozen after placement and add a boolean `collected[m][p]`. Item
5's "once" becomes structural, which tempted me. But the observable share is
zero after collection, so `Observe` would have to compute it (zero under the
flag, else the frozen entry), and the fourth variable needs its own invariant
to stay honest. Zeroing the share keeps the observable and the variable
identical, and the `share[m][p] > 0` guard carries "once" on its own. I think
the flag version is defensible. It just buys nothing the guard doesn't.

## Partial maps for shares

`share` defined only on placed and arrived products. The domain then moves
with the phase, `TypeOK` goes conditional, and `Observe` needs a default to
show a value for every member and product anyway. A total map with zero for
"nothing standing" says the same thing without a moving domain, and it matches
the book's own zero-means-none convention.

## Phase sets

Three product sets (open, placed, arrived) instead of a phase function. Same
information, plus a partition invariant to keep the sets disjoint and
exhaustive. The observable is "for each product, which phase", which is a
function already.

## Curried or paired

`book[m][p]` over `book[<<m, p>>]`. Curried won because `EXCEPT` names one
entry in one hop, and a member's row stays a first-class thing, which is how
the description talks about the book.

## Strings for phases

Model values would add cfg plumbing for a fixed three-word vocabulary, and the
strings print as corkboard facts in traces and in `Observe`.

## The pledge no-op

Not state, but nearby. `Pledge` requires the new number to differ from the
standing one. Allowing the no-op adds self-loops the action properties exempt
as stutters anyway. I kept the exclusion so every pledge step is a real book
move.
