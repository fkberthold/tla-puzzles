# Property 10: a proposal holds its day

A parent's outstanding proposal never trades one day for another in a
single step. If p has a proposal before a step and after it, it names the
same day.

## Satisfies it

`full-window.md`. Follow A's column: none, day 9, none, day 3, none,
day 12, none. Every change either starts from none or returns to none.
The same holds for B's. Nobody's proposal ever reads day x on one row and
day y on the next.

## Violates it

A model that lets a parent replace an outstanding proposal in place.

| # | today | custody, days 1-14 | A proposes | B proposes | step |
|---|---|---|---|---|---|
| 1 | none yet | `AAABAAA BBBABBB` | none | none | the window opens |
| 2 | none yet | `AAABAAA BBBABBB` | day 1 | none | A proposes the swap of day 1 |
| 3 | none yet | `AAABAAA BBBABBB` | day 2 | none | A's proposal now names day 2. The day 1 proposal was never resolved |

**Where it breaks:** the step into state 3. A's proposal read day 1 before
and day 2 after, in one step. Rule 7 says a parent makes no new proposal
until the outstanding one is resolved, and rule 8 says resolution is how a
proposal ends: accepted, dropped, or voided. A swap-in-place is a new
proposal that skipped the resolution, and B never got the chance to accept
or decline the day 1 offer that silently vanished. Naming a new day takes
two steps.
