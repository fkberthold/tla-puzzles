# Property 9: the window runs

At the opening, no day has begun. The latest begun day moves only from none
to day 1 and from day k to day k+1. And day H eventually begins.

## Satisfies it

`full-window.md`. `today` reads "none yet" at state 1, then visits 1
through 14 in order, one day per beginning, interleaved freely with the
parents' steps. Day 14 begins at state 24.

## Violates it, first way: the days never come

A model where nothing obliges a day to begin. The behavior below is not a
finite trace that ends. It is an infinite behavior in which, after state 4,
nothing ever happens again.

| # | today | custody, days 1-14 | A proposes | B proposes | step |
|---|---|---|---|---|---|
| 1 | none yet | `AAABAAA BBBABBB` | none | none | the window opens |
| 2 | none yet | `AAABAAA BBBABBB` | day 4 | none | A proposes the swap of day 4 |
| 3 | none yet | `AAAAAAA BBBABBB` | none | none | the swap of day 4 is agreed |
| 4 | 1 | `AAAAAAA BBBABBB` | none | none | day 1 begins |
| ∞ | 1 | `AAAAAAA BBBABBB` | none | none | and then nothing, forever. Day 2 never begins. Day 14 never comes |

**Where it breaks:** nowhere you can point to a bad state, which is the
lesson. Every state above is fine. The violation is the whole behavior:
"day 14 eventually begins" is a promise about forever, and a model can
describe every legal step correctly and still never oblige the days to
pass. The system says days begin on their own, without either parent's
leave. Your model has to make that true, not merely possible. When TLC
shows you a trace that ends in stuttering, this is what it is saying.

## Violates it, second way: the days come wrong

A model that begins two days in one step.

| # | today | custody, days 1-14 | A proposes | B proposes | step |
|---|---|---|---|---|---|
| 1 | none yet | `AAABAAA BBBABBB` | none | none | the window opens |
| 2 | 2 | `AAABAAA BBBABBB` | none | none | two days begin at once: today jumps from none to 2 |

**Where it breaks:** the step into state 2. The latest begun day may move
from none only to day 1. Day 1 never begins on its own here, it gets
swallowed. Days begin one at a time, in order, and the observation must
show every one of them.
