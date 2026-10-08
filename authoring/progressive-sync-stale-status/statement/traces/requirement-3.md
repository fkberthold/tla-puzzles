# Requirement 3: one district at a time

Every box under issue belongs to the district in hand, so no box is under
issue before the circulation opens or after it ends.

## Satisfies it

`full-circulation.md`. `underIssue` is empty at rows 1 to 3, before the
opening. It holds b1 while `inHand` is 1, holds b2 and then b3 while `inHand`
is 2, and is empty again at row 17 when `inHand` reads 3. At rows 8 and 17,
the two sign-offs, it's empty.

## Violates it

A model that signs a district off on the boxes it has got out, without
waiting for the issues to close.

| # | amendment | working b1 b2 b3 | inHand | underIssue | signedOff | step |
|---|---|---|---|---|---|---|
| 1 | 0 | 0 0 0 | 0 | `{}` | `{}` | the opening |
| 2 | 1 | 0 0 0 | 0 | `{}` | `{}` | head office issues the amendment |
| 3 | 1 | 0 0 0 | 1 | `{}` | `{}` | she takes district 1 in hand |
| 4 | 1 | 0 0 0 | 1 | `{b1}` | `{}` | she issues to b1 |
| 5 | 1 | 0 0 0 | 2 | `{b1}` | `{1}` | she signs district 1 off with b1's issue still standing |

**Where it breaks:** state 5. b1 is under issue and `inHand` reads 2, so b1
isn't in the district in hand. She has an outstanding issue in a district she
has closed, and rule 7 won't let her go back to it.

The after-it-ends half of this requirement is the one that goes untested on
a small instance. Here it would need `inHand` to read 3 with something still
under issue. Signing the last district off is the step that gets you there,
and a model that holds the issues open through it fails this requirement at
the very end of a run rather than in the middle.
