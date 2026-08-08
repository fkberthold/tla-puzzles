# Property 2: the opening baseline

At the opening, each day's custodian is its scheduled parent.

## Satisfies it

`full-window.md`, state 1. The custody string at the opening is
`AAABAAA BBBABBB`, which is the scheduled string exactly: base pattern,
day 4 to B, day 11 to A, no swaps yet.

## Violates it

A model that opens with day 1 already swapped.

| # | today | custody, days 1-14 | A proposes | B proposes | step |
|---|---|---|---|---|---|
| 1 | none yet | `BAABAAA BBBABBB` | none | none | the window opens |

**Where it breaks:** state 1, before anything happens at all. Day 1 is
scheduled to A and the model opens it with B. No proposal, no acceptance,
no window activity of any kind can explain it. The violation is one state
long, which is what makes it worth staring at: get the opening wrong and
nothing your steps do afterwards can be trusted.
