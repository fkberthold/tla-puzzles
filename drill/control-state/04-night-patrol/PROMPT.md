# The night round

A night guard walks a fixed round of three checkpoints in a loop: 1, then
2, then 3, then back to 1. At each checkpoint there is a key the guard
turns in the clock to log the visit. The guard logs the checkpoint they
are standing at and then walks on to the next one. A checkpoint already
logged tonight is not logged again, so after one full round the guard
just keeps walking.

The guard never stops for good. Whatever the guard is able to do next,
they eventually do.

**Every checkpoint gets logged tonight.** That is the property to check.

Write the specification and the property from an empty file, including
the statement that the guard never stops for good, and run it. Report the
verdict. If TLC reports a counter-example, say at which state the guard
stopped and what the guard was able to do there.

Then: the guard's position is not something the clock records. Say in one
sentence whether it belongs in your specification's state at all.
