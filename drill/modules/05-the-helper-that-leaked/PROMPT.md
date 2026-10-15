# The helper that leaked

Eight minutes of thinking. Every run is under a second.

## The system

A conveyor with twenty-four stations, driven by a gear on a
twelve-position clock face. Each advance turns the gear four teeth round
the face and moves the belt four stations round the loop. Both start at
zero.

Three files. The clock face is shared with three other specs and defines
one thing: wrapping a number round twelve. You can't edit it. The
gearing helper brings the clock face in, keeps a private tooth count of
four, and offers one operator, turn, which advances a face position by
that many teeth. The conveyor brings the helper in and wants only turn
from it. The conveyor has its own tooth count (twenty-four, the
stations) and its own wrap (round twenty-four), under those same two
names.

The requirement: the belt stays in step with the gear. The belt's
position modulo twelve equals the gear's position. Also the belt is
always at a real station.

## What happened

| model | verdict | distinct states |
|---|---|---|
| the conveyor, as described | clean | 6 |
| the helper as first written, conveyor unchanged | refused: two of the conveyor's names were already defined | |
| the conveyor leaving out its own wrap and tooth count, helper as first written | clean | 3 |
| the helper as first written, conveyor bringing it in under a name instead | clean | 6 |

## The questions

1. Write the three files so row one holds.
2. Row two: the helper leaked two names into the conveyor. One is the
   helper's own scratch definition. The other the helper didn't even
   write. Where did it come from, and what stops each one traveling?
3. Row three is the dangerous one. Nothing was refused. Where did the
   belt get its wrap from, and why 3?
4. Row four fixes it from the other side without touching the helper.
   What changed in the conveyor?

Write it, reproduce the 6, then take the marks off and watch both names
arrive.
