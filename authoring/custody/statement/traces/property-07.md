# Property 7: the cap

At every moment, at most N days have a custodian other than their scheduled
parent. Here N = 2.

## Satisfies it

`full-window.md`. Zero letters differ from the scheduled string through
state 3, one from state 4 (day 6), two from state 12 (days 6 and 12). Never
three. And the model keeps living under the cap correctly: B's day-13
proposal at state 13 stays proposable, it just can never be accepted.

## Violates it

A model that agrees a third swap.

| # | today | custody, days 1-14 | A proposes | B proposes | step |
|---|---|---|---|---|---|
| 1 | none yet | `AAABAAA BBBABBB` | none | none | the window opens |
| 2 | none yet | `AAABAAA BBBABBB` | day 1 | none | A proposes the swap of day 1 |
| 3 | none yet | `BAABAAA BBBABBB` | none | none | the swap of day 1 is agreed |
| 4 | none yet | `BAABAAA BBBABBB` | day 2 | none | A proposes the swap of day 2 |
| 5 | none yet | `BBABAAA BBBABBB` | none | none | the swap of day 2 is agreed |
| 6 | none yet | `BBABAAA BBBABBB` | day 3 | none | A proposes the swap of day 3 |
| 7 | none yet | `BBBBAAA BBBABBB` | none | none | the swap of day 3 is agreed, the third |

**Where it breaks:** state 7. Days 1, 2 and 3 all differ from their
scheduled parent, three days off schedule against a cap of two. The trap in
practice is the boundary again: with two swaps already agreed, acceptance
must be unavailable. A model that asks "were we at or under the cap?"
instead of "are we strictly under it?" admits exactly one swap too many.
