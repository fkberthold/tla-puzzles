# A clean run, and a colleague's deadlock

Ten minutes of thinking. Every run is under a second.

## The system

Two workers, two locks. Each worker takes both locks one at a time,
works, then releases both. The requirement you wrote: a worker that's
working holds both locks.

You know the ordering bug is in this model. One worker takes the locks
in the opposite order to the other. The requirement above can't see an
ordering bug, and the stuck-state check can. So you wrote the config
asking TLC to check for a stuck state.

## What happened

Your run came back clean. 13 distinct states, depth 7, 0.3 seconds.

A colleague ran your two files unchanged on the same TLC build. Theirs
stopped at depth 4 with 7 distinct states and reported the stuck state,
two workers each holding the other's first lock.

Same module, same config, same build, different verdict.

## The questions

1. What differed, and why did your run say nothing about it? You can
   settle this by running the same pair six ways.
2. Fix the ordering. Now a run with the stuck-state check on reports a
   stuck state at depth 7. Is that one real?
3. There are two ways to make the fixed model come back clean with the
   check on. One throws away the check. The other keeps it. Build both
   and run the buggy ordering through the second one.

Write the module and the configs. Reproduce the 7 and the 13 on the
buggy ordering before you fix anything.
