# The view that hides the bug

Ten minutes of thinking. One run you'll kill at 30 seconds. The rest are
under a second.

## Two clients

Both retry a failing job. Both have a budget of three failures. Both are
meant to give up on the fourth. Both have the same off-by-one, which lets
a fourth retry through.

**Client A** keeps a log of every attempt's outcome and decides whether
to retry by counting the errors in that log. Nothing else in it counts
anything.

**Client B** keeps a retry counter, reset on every new submission, and
decides from the counter. It also keeps the same outcome log, appended on
every attempt, but nothing in B ever reads the log. It's there for
whoever reads traces. A job can be resubmitted after it finishes, forever.

The requirement for both: the number of failures a job has been through
never exceeds the budget.

## What happened

| run | verdict | distinct states | depth | wall time |
|---|---|---|---|---|
| A, as written | violation | 12 | 8 | 0.3 s |
| B, as written | violation | 45 | 8 | 0.3 s |

Both bugs found. Then I fixed B's off-by-one and ran it again, and it was
at 2,628,536 distinct states after 30 seconds. I killed it.

A colleague said the log isn't state, it's a trail, and TLC shouldn't be
telling states apart by it. There's a way to say that to TLC. I said it
for B.

| run | verdict | distinct states | depth | wall time |
|---|---|---|---|---|
| B fixed, log hidden | clean | 10 | 7 | 0.3 s |

Thirty seconds to ten states. So I said the same thing for A, bug still
in.

| run | verdict | distinct states | depth | wall time |
|---|---|---|---|---|
| A buggy, log hidden | clean | 3 | 2 | 0.3 s |

## The questions

1. One of those two "clean" results is wrong. Which, and why does the
   same instruction produce a true answer on B and a false one on A?
2. What does the instruction change in TLC, and what doesn't it change?
   The 3 and the 2 are the clue.
3. State the condition under which hiding a variable is safe, in one
   sentence you could check by reading the module.
4. Before you had the colleague's idea, what was the other knob for B's
   blow-up, and what would it have cost?

Write both modules and the four configs. Get the 3 before you believe
the 10.
