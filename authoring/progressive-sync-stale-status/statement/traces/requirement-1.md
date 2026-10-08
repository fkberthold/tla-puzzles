# Requirement 1: a sign-off says what it means

Whenever a district is signed off, every box in that district works to the
amendment being circulated.

## Satisfies it

`full-circulation.md`. District 1 is signed off at row 8, and b1 has worked
to the amendment since row 5. District 2 is signed off at row 17, and b2 and
b3 got there at rows 10 and 14. Every sign-off in the run comes after the
last box of its district has pasted.

## Violates it

A model whose superintendent reads the board's verdict on a box and doesn't
ask which amendment that verdict was reached against. Rule 8 puts the board
in agreement with every box at the opening, so every line already reads well
of its box before the amendment lands. She closes an issue off on that, and
nothing in the five fields looks wrong until she signs.

| # | amendment | working b1 b2 b3 | inHand | underIssue | signedOff | step |
|---|---|---|---|---|---|---|
| 1 | 0 | 0 0 0 | 0 | `{}` | `{}` | the opening |
| 2 | 1 | 0 0 0 | 0 | `{}` | `{}` | head office issues the amendment |
| 3 | 1 | 0 0 0 | 1 | `{}` | `{}` | she takes district 1 in hand |
| 4 | 1 | 0 0 0 | 1 | `{b1}` | `{}` | she issues to b1 |
| 5 | 1 | 0 0 0 | 1 | `{}` | `{}` | she reads b1's line, finds nothing wrong with it, and closes the issue off |
| 6 | 1 | 0 0 0 | 2 | `{}` | `{1}` | she signs district 1 off |

**Where it breaks:** state 6. District 1 is signed off and b1 is still working
to the standing edition. The amendment never went into that book. It never
will either, because rule 7 makes a sign-off final.

This is the whole problem in five steps. b1 never pasted, no clerk ever went
near it, and the line she read was written before there was an amendment to
read it against. The board was right when it was written and wrong when she
used it, and nothing in the circulation makes a line say which of those it is.

If your first attempt doesn't produce a trace of this shape, that's worth
checking before you go on. Either you've already written the guard that
catches it, or your superintendent is learning b1's state by some route the
rules don't give her.

Requirement 5 catches the same model on a longer run, because b1 is free to
paste the amendment in after she has closed its issue off, and at that step
b1 isn't under issue. So you may see requirement 5 go red first depending on
what order you declare them in. The two are reading different things and
both are worth keeping.
