# Property 4: flips come from acceptance

A day's custodian changes only in a step where a proposal naming that day
was outstanding just before and is gone just after. Nothing else moves
custody.

## Satisfies it

`full-window.md`. Custody changes exactly twice, at states 4 and 12. Both
times, look one row up: a proposal naming that day was outstanding, and in
the flipping step it is gone. Now look at the steps that do not flip:
A's withdrawal at state 6 moves nothing, the voiding at state 9 moves
nothing, and fourteen day-beginnings move nothing.

## Violates it

A model where a swap can land without any proposal at all.

| # | today | custody, days 1-14 | A proposes | B proposes | step |
|---|---|---|---|---|---|
| 1 | none yet | `AAABAAA BBBABBB` | none | none | the window opens |
| 2 | none yet | `BAABAAA BBBABBB` | none | none | day 1 goes to B, out of nowhere |

**Where it breaks:** the step into state 2. Day 1's custodian changed, and
neither parent had a proposal outstanding, before or after. At the
interface a flip with no resolving proposal is a swap nobody agreed to.
Rule 6 says no swap exists without both parents.
