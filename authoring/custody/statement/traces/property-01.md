# Property 1: total custody

At every moment, every day of the window has exactly one custodian, A or B.

## Satisfies it

`full-window.md`, every state. Every row's custody string is fourteen
letters, each one A or B, from the opening to the end. No day is ever
blank, shared, or anything else.

## Violates it

A model where an agreed swap loses the day: the swapped day's custodian
comes back as nobody.

| # | today | custody, days 1-14 | A proposes | B proposes | step |
|---|---|---|---|---|---|
| 1 | none yet | `AAABAAA BBBABBB` | none | none | the window opens |
| 2 | none yet | `AAABAAA BBBABBB` | day 1 | none | A proposes the swap of day 1 |
| 3 | none yet | `-AABAAA BBBABBB` | none | none | the swap of day 1 is agreed, and day 1's custodian is now nobody |

**Where it breaks:** state 3. Ask who has day 1 and the answer is neither
parent. The swap was supposed to hand day 1 to the other parent, and this
model dropped it instead.
