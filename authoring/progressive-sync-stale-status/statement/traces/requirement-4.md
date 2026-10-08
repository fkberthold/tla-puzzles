# Requirement 4: the cap holds on the last district

At no moment are more than `Cap` boxes of the last district under issue.

## Satisfies it

`full-circulation.md` at `Cap = 1`. `underIssue` never holds two boxes of
district 2. b2 is out alone from row 9 to row 11, its issue closes at row 12,
and b3 goes out at row 13. The run is longer than it needs to be for exactly
that reason.

## Violates it

A model with no cap on the last district, or with a cap counted over the
whole of `Boxes` rather than over the last district's share of it.

| # | amendment | working b1 b2 b3 | inHand | underIssue | signedOff | step |
|---|---|---|---|---|---|---|
| 1 | 0 | 0 0 0 | 0 | `{}` | `{}` | the opening |
| 2 | 1 | 0 0 0 | 0 | `{}` | `{}` | head office issues the amendment |
| 3 | 1 | 0 0 0 | 1 | `{}` | `{}` | she takes district 1 in hand |
| 4 | 1 | 0 0 0 | 1 | `{b1}` | `{}` | she issues to b1 |
| 5 | 1 | 1 0 0 | 1 | `{b1}` | `{}` | b1 pastes the amendment in |
| 6 | 1 | 1 0 0 | 1 | `{b1}` | `{}` | the clerk looks at b1 |
| 7 | 1 | 1 0 0 | 1 | `{}` | `{}` | she closes b1's issue off |
| 8 | 1 | 1 0 0 | 2 | `{}` | `{1}` | she signs district 1 off |
| 9 | 1 | 1 0 0 | 2 | `{b2}` | `{1}` | she issues to b2 |
| 10 | 1 | 1 0 0 | 2 | `{b2,b3}` | `{1}` | she issues to b3 with b2 still out |

**Where it breaks:** state 10. Two boxes of the last district are under issue
and `Cap` is 1. Rows 1 to 9 are a legal run, which is why this one takes nine
steps to get wrong.

Note which district it happens in. b1 is the whole of district 1, so a model
that caps every district instead of only the last one still comes out green
on this instance. That bug needs a first district with two boxes in it to
show up, and the checking instance doesn't have one. Requirement 4 is a
one-way check here: it catches a cap that's too loose and not a cap that's
too tight.
