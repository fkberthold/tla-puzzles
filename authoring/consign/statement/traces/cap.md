# Obligation 3, the cap: a trace pair

The book never shows more than `Floor` items listed at once. In this
instance the floor holds two.

## A trace that satisfies it

| state | lamp | clock | radio | vase |
|---|---|---|---|---|
| 1 | unlisted | unlisted | unlisted | unlisted |
| 2 | listed | unlisted | unlisted | unlisted |
| 3 | sold | unlisted | unlisted | unlisted |
| 4 | sold | listed | unlisted | unlisted |
| 5 | sold | listed | listed | unlisted |

Count the listed items state by state: 0, 1, 0, 1, 2. The floor ends at its
cap and never goes past it.

## A trace that violates it

| state | lamp | clock | radio | vase |
|---|---|---|---|---|
| 1 | unlisted | unlisted | unlisted | unlisted |
| 2 | listed | unlisted | unlisted | unlisted |
| 3 | listed | listed | unlisted | unlisted |
| 4 | listed | listed | listed | unlisted |

Three items on a floor that holds two. The third intake should have been
refused, and the book shows it went through anyway.
