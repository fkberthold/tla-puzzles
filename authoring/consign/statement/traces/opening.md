# Obligation 1, the opening: a trace pair

At the start of the round, the book shows every item unlisted.

## A trace that satisfies it

| state | lamp | clock | radio | vase |
|---|---|---|---|---|
| 1 | unlisted | unlisted | unlisted | unlisted |
| 2 | listed | unlisted | unlisted | unlisted |

The round opens with every item home, and then Ann brings the lamp in. The
opening state is the one this obligation reads, and here it's right.

## A trace that violates it

| state | lamp | clock | radio | vase |
|---|---|---|---|---|
| 1 | listed | unlisted | unlisted | unlisted |

The book's first state already shows the lamp on the floor. Nothing needs to
happen after that. This obligation is about the opening alone, so the
violating trace is one state long.
