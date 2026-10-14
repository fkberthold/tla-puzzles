# Print job

A printer has one job slot. At any moment the slot is empty, holds a queued
job, or holds a printed job waiting to be collected.

Below are six behaviors of the slot, left to right. "Then forever" means the
last state repeats without end. "Cycling" means the bracketed run repeats
without end.

| # | the slot, over time | verdict |
|---|---|---|
| 1 | empty, queued, queued, printed, then printed forever | allowed |
| 2 | empty, then empty forever | allowed |
| 3 | empty, queued, then queued forever | forbidden |
| 4 | queued, printed, queued, then queued forever | forbidden |
| 5 | empty, queued, printed, empty, then empty forever | allowed |
| 6 | (queued, empty) cycling | forbidden |

Write the one temporal property that admits every allowed behavior and
rejects every forbidden one. Define any state predicate it uses. One line
for the property.
