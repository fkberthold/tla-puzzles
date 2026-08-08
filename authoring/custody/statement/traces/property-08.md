# Property 8: quiet at the end

Once day H has begun, nothing observable changes. Here H = 14.

## Satisfies it

`full-window.md`, state 24. Day 14 begins and the behavior has nowhere else
to go: no field changes again, and the window just plays out. Note the
arrangement got its housekeeping done on the way in, at state 23, where the
last outstanding proposal died of its own day beginning.

## Violates it

The same behavior as `property-05.md`, read against the end of the window
instead of the beginning. Fourteen day-beginnings, and then, with the
window fully begun, custody moves.

| # | today | custody, days 1-14 | A proposes | B proposes | step |
|---|---|---|---|---|---|
| 14 | 13 | `AAABAAA BBBABBB` | none | none | day 13 begins |
| 15 | 14 | `AAABAAA BBBABBB` | none | none | day 14 begins |
| 16 | 14 | `BAABAAA BBBABBB` | none | none | day 1's custody changes, after day 14 has begun |

(States 1 through 13 are the quiet march in `property-05.md`.)

**Where it breaks:** the step into state 16. Day 14 began at state 15, so
the window is over as a matter of activity: rule 1 permits no further step.
This model still has a move left, and the observation shows it. If your
model does anything at all after day H begins, this is the counterexample
shape TLC will hand you.
