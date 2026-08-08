# Obligation 4, one way only: a trace pair

The book never shows an item change standing except by one of the four
lawful moves: taken in, sold, home unsold, paid out.

## A trace that satisfies it

| state | lamp | clock | radio | vase |
|---|---|---|---|---|
| 1 | unlisted | unlisted | unlisted | unlisted |
| 2 | listed | unlisted | unlisted | unlisted |
| 3 | sold | unlisted | unlisted | unlisted |
| 4 | sold | listed | unlisted | unlisted |
| 5 | sold | returned | unlisted | unlisted |
| 6 | settled | returned | unlisted | unlisted |

All four lawful moves appear: two intakes, a sale, a going-home, a payout.
The lamp lives a whole story, unlisted to listed to sold to settled. The
clock takes its one turn on the floor and goes home. Nothing moves backward
and nothing skips a stop.

## A trace that violates it

| state | lamp | clock | radio | vase |
|---|---|---|---|---|
| 1 | unlisted | unlisted | unlisted | unlisted |
| 2 | listed | unlisted | unlisted | unlisted |
| 3 | sold | unlisted | unlisted | unlisted |
| 4 | returned | unlisted | unlisted | unlisted |

Between states 3 and 4 the sold lamp goes home as if it were never sold.
Sold to returned is not one of the four moves, and the payout the shop owed
Ann vanishes from the book with it.
