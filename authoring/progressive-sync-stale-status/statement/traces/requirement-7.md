# Requirement 7: the amendment reaches every box

Every box ends up working to the amendment being circulated, and stays there.

## Satisfies it

`full-circulation.md`. `working` reads `1 1 1` from row 14 to the end, and
the amendment is 1, so the three boxes all end up on it. A run in which head
office never issues also satisfies this requirement, because the amendment
stays at the standing edition and every box is already on it.

## Violates it

A model that puts no obligation on the clerk. The behavior below isn't a
finite run that ends. It's an infinite behavior in which, after row 10,
nothing ever happens again.

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
| 10 | 1 | 1 1 0 | 2 | `{b2}` | `{1}` | b2 pastes the amendment in |
| ∞ | 1 | 1 1 0 | 2 | `{b2}` | `{1}` | and then nothing, forever. The clerk never goes near b2 again |

**Where it breaks:** nowhere you can point to a bad state, which is the
lesson. Every row above is fine. The violation is the whole behavior. b2's
line never comes current, so she can never close that issue off. The cap
keeps b3 from going out while b2 is still under issue, so b3 never gets the
amendment at all, and `working` sits at `1 1 0` forever.

Rule 9 puts three parties on the hook and the clerk is the one people leave
out. He looks like scenery. He isn't: the whole circulation is waiting on his
round, one box at a time, and a clerk who neglects one box forever stalls her
as surely as she can stall herself.

## What this requirement doesn't catch

"Ends up working to it, and stays there" holds over a model that can never
open a circulation. Nothing is ever issued, every box stays on the standing
edition, the standing edition is the current amendment, and the requirement
is true of every run for free. That's why `Checking` asks you to produce a
run that finishes as well as one that never starts. Neither probe is a
requirement, and requirement 7 can't do their job.
