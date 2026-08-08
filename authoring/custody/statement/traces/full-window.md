# A full window that goes right

One behavior, opening to day 14. It satisfies all ten properties, and each
property file points back into it. Two swaps get agreed here (days 6 and 12),
one proposal is withdrawn, two are voided, and the cap turns a late proposal
into a dead letter. Nothing below is required of your model except that it
allow behaviors like this one.

| # | today | custody, days 1-14 | A proposes | B proposes | step |
|---|---|---|---|---|---|
| 1 | none yet | `AAABAAA BBBABBB` | none | none | the window opens |
| 2 | none yet | `AAABAAA BBBABBB` | none | day 6 | B proposes the swap of day 6, a day A holds |
| 3 | 1 | `AAABAAA BBBABBB` | none | day 6 | day 1 begins |
| 4 | 1 | `AAABABA BBBABBB` | none | none | A accepts. The swap of day 6 is agreed |
| 5 | 1 | `AAABABA BBBABBB` | day 9 | none | A proposes the swap of day 9 |
| 6 | 1 | `AAABABA BBBABBB` | none | none | A withdraws it. Custody untouched |
| 7 | 2 | `AAABABA BBBABBB` | none | none | day 2 begins |
| 8 | 2 | `AAABABA BBBABBB` | day 3 | none | A proposes the swap of day 3, a day A holds |
| 9 | 3 | `AAABABA BBBABBB` | none | none | day 3 begins. A's proposal is void that same moment |
| 10 | 3 | `AAABABA BBBABBB` | day 12 | none | A proposes the swap of day 12 |
| 11 | 3 | `AAABABA BBBABBB` | day 12 | day 12 | B proposes the swap of day 12 too. Same day, same swap |
| 12 | 3 | `AAABABA BBBAABB` | none | none | one proposal is accepted. The swap of day 12 is agreed, and the other proposal is void that same moment |
| 13 | 3 | `AAABABA BBBAABB` | none | day 13 | B proposes the swap of day 13. The cap is full, so this one can only end dropped or voided |
| 14 | 4 | `AAABABA BBBAABB` | none | day 13 | day 4 begins |
| 15 | 5 | `AAABABA BBBAABB` | none | day 13 | day 5 begins |
| 16 | 6 | `AAABABA BBBAABB` | none | day 13 | day 6 begins |
| 17 | 7 | `AAABABA BBBAABB` | none | day 13 | day 7 begins |
| 18 | 8 | `AAABABA BBBAABB` | none | day 13 | day 8 begins |
| 19 | 9 | `AAABABA BBBAABB` | none | day 13 | day 9 begins |
| 20 | 10 | `AAABABA BBBAABB` | none | day 13 | day 10 begins |
| 21 | 11 | `AAABABA BBBAABB` | none | day 13 | day 11 begins |
| 22 | 12 | `AAABABA BBBAABB` | none | day 13 | day 12 begins |
| 23 | 13 | `AAABABA BBBAABB` | none | none | day 13 begins. B's proposal is void |
| 24 | 14 | `AAABABA BBBAABB` | none | none | day 14 begins. The window has played out |

Worth noticing on the way through:

- Custody changes exactly twice, at states 4 and 12, and each time a proposal
  naming that day resolves in the same step. The withdrawal at state 6 and
  the voidings at states 9, 12 and 23 move nothing.
- Day 6 was scheduled to A and ends with B. Day 12 was scheduled to B and
  ends with A. A swap reverses whatever the schedule settled, in either
  direction.
- From state 12 on, exactly two letters differ from the scheduled string.
  The cap N = 2 is reached, so B's day-13 proposal at state 13 can never be
  accepted. It waits ten states and dies of its own day beginning.
- `today` visits every value from none to 14, one day at a time, and gets
  there.
