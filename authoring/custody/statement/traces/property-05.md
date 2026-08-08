# Property 5: the past is fixed

Once a day has begun, its custodian never changes.

## Satisfies it

`full-window.md`. Days 1, 2 and 3 have begun by state 9, and their three
letters never move through state 24. The two flips in the behavior (states
4 and 12) both land on days that had not begun yet.

## Violates it

A model that lets custody churn after days have begun. Fourteen quiet
day-beginnings, then it rewrites history.

| # | today | custody, days 1-14 | A proposes | B proposes | step |
|---|---|---|---|---|---|
| 1 | none yet | `AAABAAA BBBABBB` | none | none | the window opens |
| 2 | 1 | `AAABAAA BBBABBB` | none | none | day 1 begins |
| 3 | 2 | `AAABAAA BBBABBB` | none | none | day 2 begins |
| 4 | 3 | `AAABAAA BBBABBB` | none | none | day 3 begins |
| 5 | 4 | `AAABAAA BBBABBB` | none | none | day 4 begins |
| 6 | 5 | `AAABAAA BBBABBB` | none | none | day 5 begins |
| 7 | 6 | `AAABAAA BBBABBB` | none | none | day 6 begins |
| 8 | 7 | `AAABAAA BBBABBB` | none | none | day 7 begins |
| 9 | 8 | `AAABAAA BBBABBB` | none | none | day 8 begins |
| 10 | 9 | `AAABAAA BBBABBB` | none | none | day 9 begins |
| 11 | 10 | `AAABAAA BBBABBB` | none | none | day 10 begins |
| 12 | 11 | `AAABAAA BBBABBB` | none | none | day 11 begins |
| 13 | 12 | `AAABAAA BBBABBB` | none | none | day 12 begins |
| 14 | 13 | `AAABAAA BBBABBB` | none | none | day 13 begins |
| 15 | 14 | `AAABAAA BBBABBB` | none | none | day 14 begins |
| 16 | 14 | `BAABAAA BBBABBB` | none | none | day 1's custody changes, thirteen days after day 1 began |

**Where it breaks:** the step into state 16. Day 1 began back at state 2.
Whoever had the child that day had the child. A model that can change a
begun day's custodian is keeping a ledger, not a record of what happened.
