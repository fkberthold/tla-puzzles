# The clock that never stops

Ten minutes of thinking. The runs you'll do are under a second each, apart
from one you should kill yourself.

## The system

A supervisor watches one primary worker through heartbeats. The primary
sends a beat whenever it's working. It can also pause, for as long as it
likes, and resume. The supervisor keeps a clock and remembers when the last
beat arrived. Once the gap since the last beat is longer than the timeout,
it promotes a standby worker onto the job.

The timeout is 2 ticks, and there's one standby. Every count below depends
on both, so a model with different ones won't reach them.

The requirement: two workers are never working the job at the same time.

The first model of this had the obvious bug. A paused primary looks dead,
the standby gets promoted, the primary wakes up, and now there are two.
The fix was fencing. Promotion marks the primary as cut off, and a cut-off
primary can't resume.

## What happened

With the bug in, the run found it at once.

| run | verdict | distinct states | depth | wall time |
|---|---|---|---|---|
| buggy, no cap on the clock | violation | 15 | 5 | 0.3 s |

With the fix in, the same run was still going 30 seconds later and had
passed 2,954,402 distinct states. I killed it.

So I capped the clock, meaning the supervisor's clock can't climb past a
number I pick, and tried five numbers. Deadlock checking was off in all
five.

| cap on the clock | verdict | distinct states | depth | wall time |
|---|---|---|---|---|
| 3 | clean | 21 | 6 | 0.3 s |
| 6 | clean | 66 | 9 | 0.3 s |
| 12 | clean | 237 | 15 | 0.3 s |
| 24 | clean | 903 | 27 | 0.3 s |
| 48 | clean | 3,531 | 51 | 0.3 s |

## The questions

1. Why did the fix turn a 0.3 second run into one that never ends, when
   the bug sat in the same unbounded model?
2. There are two places to put that cap, and they aren't the same thing.
   Name both, and say what TLC checked differently under each. The
   state counts above are a clue to one of the differences.
3. Say what the supervisor reads to make its decision. Is there a model
   where nothing needs capping?

Write the module and the two config files. Reproduce the 237 figure on
whichever route you take first, then try the other route at the same cap
and look at what moved.
