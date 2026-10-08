# Requirement 6: the circulation never goes back

At a step, no district leaves the signed-off list, and the district in hand
never falls.

## Satisfies it

`full-circulation.md`. `signedOff` goes from `{}` to `{1}` at row 8 and to
`{1,2}` at row 17, and never loses a member. `inHand` reads 0, then 1 at row
3, then 2 at row 8, then 3 at row 17. It only ever climbs.

## Violates it

A model that lets her take a district back in hand once she has signed it
off, to go and sort out a box she isn't happy with.

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
| 9 | 1 | 1 0 0 | 1 | `{}` | `{}` | she takes district 1 back in hand |

**Where it breaks:** the step into state 9. District 1 leaves `signedOff` and
`inHand` falls from 2 to 1. Both halves of the requirement break at the same
step, which is common for this one and not something to count on.

Watch what this run does to the other six. Rows 1 to 8 are legal, state 9 on
its own looks like a legal state, and the only thing wrong is the transition.
A model that allows reopening still comes out green on requirements 1, 2, 4
and 5, so four of the seven have nothing to say about it.

Two of the others do fire, and neither is reading what requirement 6 reads.
Requirement 3 catches it from the side, because she can reopen district 1
while a box of district 2 is still under issue, and then `underIssue` holds a
box that isn't in the district in hand. Requirement 7 breaks because a
circulation that can go back can go round forever and never finish. Only
requirement 6 reads the direction of travel itself, which is why it's
declared on its own.
