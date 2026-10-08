# Allowed

Two behaviours the standing orders permit. All three requirements hold at every
state of both. A model that can't produce both is over-constrained, however
green its checks are.

## The whole set goes over

| # | sending | receiving | answer | step |
|---|---|---|---|---|
| 1 | m1 on, m2 on | m1 off, m2 off | waiting | the instruction is in the clerk's hands |
| 2 | m1 off, m2 on | m1 on, m2 off | waiting | m1 goes over whole, in one moment |
| 3 | m1 off, m2 off | m1 on, m2 on | waiting | m2 goes over the same way |
| 4 | m1 off, m2 off | m1 on, m2 on | done | every member named has gone over, so the clerk reports it done |

## It fails partway through the set

| # | sending | receiving | answer | step |
|---|---|---|---|---|
| 1 | m1 on, m2 on | m1 off, m2 off | waiting | the instruction is in the clerk's hands |
| 2 | m1 off, m2 on | m1 on, m2 off | waiting | m1 goes over whole, in one moment |
| 3 | m1 off, m2 on | m1 on, m2 off | refused | m2 doesn't go over, so the clerk reports the instruction refused |

The second run is the subject of the problem. m1 sits on the receiving roll, m2
sits where she started, the answer is a flat refusal, and none of that is a
breach. Rule 5 lets the clerk refuse whenever the whole set hasn't gone over,
and she says nothing about which members she got to.

A model that always carries the instruction out can't produce the second run.
Its checks go green and it isn't the system this statement describes.
