# The full circulation

One amendment, three boxes, two districts, `Cap = 1`. The opening, then
district 1, then district 2, then the last sign-off. It satisfies all seven
requirements.

**Your model must allow this run.** Nothing else in `traces/` tests that
direction, and no requirement does either.

| # | amendment | working b1 b2 b3 | inHand | underIssue | signedOff | step |
|---|---|---|---|---|---|---|
| 1 | 0 | 0 0 0 | 0 | `{}` | `{}` | the opening |
| 2 | 1 | 0 0 0 | 0 | `{}` | `{}` | head office issues the amendment |
| 3 | 1 | 0 0 0 | 1 | `{}` | `{}` | she takes district 1 in hand |
| 4 | 1 | 0 0 0 | 1 | `{b1}` | `{}` | she issues to b1 |
| 5 | 1 | 1 0 0 | 1 | `{b1}` | `{}` | b1 pastes the amendment into its book |
| 6 | 1 | 1 0 0 | 1 | `{b1}` | `{}` | the clerk looks at b1 and writes his line |
| 7 | 1 | 1 0 0 | 1 | `{}` | `{}` | she reads b1's line and closes the issue off |
| 8 | 1 | 1 0 0 | 2 | `{}` | `{1}` | she signs district 1 off, and district 2 comes in hand |
| 9 | 1 | 1 0 0 | 2 | `{b2}` | `{1}` | she issues to b2 |
| 10 | 1 | 1 1 0 | 2 | `{b2}` | `{1}` | b2 pastes the amendment in |
| 11 | 1 | 1 1 0 | 2 | `{b2}` | `{1}` | the clerk looks at b2 |
| 12 | 1 | 1 1 0 | 2 | `{}` | `{1}` | she closes b2's issue off |
| 13 | 1 | 1 1 0 | 2 | `{b3}` | `{1}` | she issues to b3, which the cap kept her from doing at row 9 |
| 14 | 1 | 1 1 1 | 2 | `{b3}` | `{1}` | b3 pastes the amendment in |
| 15 | 1 | 1 1 1 | 2 | `{b3}` | `{1}` | the clerk looks at b3 |
| 16 | 1 | 1 1 1 | 2 | `{}` | `{1}` | she closes b3's issue off |
| 17 | 1 | 1 1 1 | 3 | `{}` | `{1,2}` | she signs district 2 off, and the circulation ends |

## Three rows that repeat, and why

Rows 6, 11 and 15 are the clerk's visits, and each one reads the same across
all five fields as the row above it. The visit moves a line on the board, the
board isn't a field, so the observation stands still while something real
happens. A model that has nothing to move at those three steps can't produce
this run.

## Four things the run pins down

**The amendment lands before the circulation opens.** Row 2 is head office's
step and row 3 is hers. They're two steps and not one, and nothing between
them is forced.

**A box stays under issue after it pastes.** Rows 5 and 6 both have b1
working to the amendment and still in `underIssue`. Pasting is the box's
step, and it doesn't take the box off her hands.

**The cap bites on the last district and nowhere else.** At row 9 she has b2
out and can't add b3, because `Cap = 1`. She gets to row 13 only after b2's
issue closes at row 12. District 1 has one box, so you can't see the cap's
absence there. A larger first district would let her have them all out at
once.

**Nothing finishes until the board catches up.** The gap between row 5 and row
7 is two steps wide: the box moves, the clerk writes, and only then does she
act. Shorten that to one step and you've modeled a superintendent who can
see into a box.
