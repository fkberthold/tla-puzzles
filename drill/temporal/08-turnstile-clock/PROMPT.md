# Turnstile and clock

A turnstile counts people entering a hall. A wall clock beside it ticks.
The clock isn't the turnstile's business.

Each row below is one step: the state before and the state after, written
(count, clock).

| # | before | after | verdict |
|---|---|---|---|
| S1 | (3, 0) | (4, 0) | allowed |
| S2 | (3, 0) | (3, 1) | allowed |
| S3 | (3, 0) | (5, 0) | forbidden |
| S4 | (3, 0) | (2, 0) | forbidden |
| S5 | (3, 0) | (4, 1) | allowed |
| S6 | (3, 0) | (3, 0) | allowed |

Write the one action property that admits every allowed step and rejects
every forbidden one. Then say, in one sentence, why S2 is allowed under
your formula.
