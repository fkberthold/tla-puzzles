# Property 6: proposals point forward

An outstanding proposal always names a day that has not begun and whose
custodian is still its scheduled parent.

## Satisfies it

`full-window.md`. Every pending value in the behavior names a day ahead of
`today` whose letter still matches the scheduled string at that moment.
Watch state 13: B proposes day 13 when today is 3, day 13 unswapped. And
watch the voidings keep the property true: at state 9 day 3 begins and A's
proposal on it vanishes in the same row, never dangling.

## Violates it

A model that lets a parent propose the day that has already begun.

| # | today | custody, days 1-14 | A proposes | B proposes | step |
|---|---|---|---|---|---|
| 1 | none yet | `AAABAAA BBBABBB` | none | none | the window opens |
| 2 | 1 | `AAABAAA BBBABBB` | none | none | day 1 begins |
| 3 | 1 | `AAABAAA BBBABBB` | day 1 | none | A proposes the swap of day 1, which is today |

**Where it breaks:** state 3. A's outstanding proposal names day 1, and day
1 has begun. Rule 7 says a proposal names a day that has not begun. A swap
of a begun day would rewrite the past, so the arrangement refuses to let
one even be proposed. The trap in practice is the boundary: "not begun"
means strictly after today, and this model let "today or later" through.
