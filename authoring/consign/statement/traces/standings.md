# Obligation 2, one standing each: a trace pair

At every moment the book gives each item exactly one of the five standings.

## A trace that satisfies it

| state | lamp | clock | radio | vase |
|---|---|---|---|---|
| 1 | unlisted | unlisted | unlisted | unlisted |
| 2 | listed | unlisted | unlisted | unlisted |
| 3 | sold | unlisted | unlisted | unlisted |
| 4 | sold | listed | unlisted | unlisted |
| 5 | sold | listed | listed | unlisted |
| 6 | sold | listed | returned | unlisted |

Six states, and every cell is one of the five spellings. By the end the book
holds four different standings at once, which is fine. The obligation is
about each cell, not about variety.

## A trace that violates it

| state | lamp | clock | radio | vase |
|---|---|---|---|---|
| 1 | unlisted | unlisted | unlisted | unlisted |
| 2 | listed | unlisted | unlisted | unlisted |
| 3 | mislaid | unlisted | unlisted | unlisted |

The lamp comes in, and then the book records it as "mislaid". A shop can
lose a lamp, but the book has no such standing. Five spellings, no sixth,
ever.
