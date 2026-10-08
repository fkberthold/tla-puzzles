# Requirement 2: no box moves ahead of its turn

At a step where a box comes under issue, every district before that box's
district in the order is already signed off.

## Satisfies it

`full-circulation.md`. b1 comes under issue at row 4 with no district before
it. b2 and b3 come under issue at rows 9 and 13, and district 1 was signed
off back at row 8. Every box of district 2 waits for that sign-off.

## Violates it

A model that lets her issue to any box she hasn't got out yet, without
checking which district it sits in.

| # | amendment | working b1 b2 b3 | inHand | underIssue | signedOff | step |
|---|---|---|---|---|---|---|
| 1 | 0 | 0 0 0 | 0 | `{}` | `{}` | the opening |
| 2 | 1 | 0 0 0 | 0 | `{}` | `{}` | head office issues the amendment |
| 3 | 1 | 0 0 0 | 1 | `{}` | `{}` | she takes district 1 in hand |
| 4 | 1 | 0 0 0 | 1 | `{b2}` | `{}` | she issues to b2, which is in district 2 |

**Where it breaks:** the step into state 4. b2 belongs to district 2, and
district 1 is not signed off. The branch line was supposed to meet the
amendment first, and the main line has it instead.

Two things about this one. It's a requirement about a step and not about a
state, so the thing that goes wrong is the transition into row 4 rather than
row 4 itself. Look at the row on its own and `inHand` reads 1 while a box of
district 2 is out, which requirement 3 also catches. Requirement 2 catches
the moment it happened.

And the subscript matters here. A step rule is only tested at steps that
change what its subscript watches. Watch `signedOff` alone and this step
changes nothing it watches, so the rule holds for free and TLC says nothing.
