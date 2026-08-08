# Obligation 5, single steps, whole payouts: a trace pair

A step that changes the book either changes exactly one item by a lawful
move that isn't a payout, or it's a settlement: every sold item of exactly
one owner turns settled at once.

## A trace that satisfies it

| state | lamp | clock | radio | vase |
|---|---|---|---|---|
| 1 | unlisted | unlisted | unlisted | unlisted |
| 2 | listed | unlisted | unlisted | unlisted |
| 3 | sold | unlisted | unlisted | unlisted |
| 4 | sold | listed | unlisted | unlisted |
| 5 | sold | sold | unlisted | unlisted |
| 6 | settled | settled | unlisted | unlisted |

Four single-item steps, and then Ann comes to the till owed both her items.
The last step settles the lamp and the clock together, one motion, touching
nothing of Ben's. A settlement is the one kind of step allowed to move more
than one item.

## A trace that violates it

| state | lamp | clock | radio | vase |
|---|---|---|---|---|
| 1 | unlisted | unlisted | unlisted | unlisted |
| 2 | listed | unlisted | unlisted | unlisted |
| 3 | sold | unlisted | unlisted | unlisted |
| 4 | sold | listed | unlisted | unlisted |
| 5 | sold | sold | unlisted | unlisted |
| 6 | settled | sold | unlisted | unlisted |

Same shop, same setup, and the last step pays Ann in parts. It changes
exactly one item, but by a payout move, and a payout step must settle
everything the shop owes that owner. The clock stays owed, so the step fits
neither lawful shape, and the checker flags exactly this step.
