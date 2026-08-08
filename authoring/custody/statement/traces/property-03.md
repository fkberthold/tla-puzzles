# Property 3: at most one flip

A day's custodian changes at most once over the whole window.

## Satisfies it

`full-window.md`. Day 6 flips at state 4 and its letter never moves again
through state 24. Day 12 flips at state 12, same story. Every other day
never flips at all.

## Violates it

A model that lets an agreed swap be undone.

| # | today | custody, days 1-14 | A proposes | B proposes | step |
|---|---|---|---|---|---|
| 1 | none yet | `AAABAAA BBBABBB` | none | none | the window opens |
| 2 | none yet | `AAABAAA BBBABBB` | day 1 | none | A proposes the swap of day 1 |
| 3 | none yet | `BAABAAA BBBABBB` | none | none | the swap of day 1 is agreed |
| 4 | none yet | `AAABAAA BBBABBB` | none | none | the agreed swap of day 1 is undone |

**Where it breaks:** state 4. Day 1 has now changed custodian twice, B and
back to A. Rule 9 says an agreed swap stands for the rest of the window,
and this model gave it a reverse gear.
