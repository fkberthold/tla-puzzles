# Two pools

A leisure centre has two bodies of water, the lanes and the leisure pool. Four
guards cover them, and one of the four is a trainee who qualified last month.

A guard is at the lanes, at the leisure pool, or on a break. He can move from
any one of those three places to either of the other two, one guard at a time.
At the start of the shift all four are on a break.

Three rules the rota has to keep:

1. No guard is at both bodies of water at once.
2. No more than two guards are at one body of water.
3. The trainee is never the only guard at a body of water.

Write the specification from an empty file, with the three rules as three named
checks, and run it with the four guards. A correct model finds 49 distinct
states.

Then take the room check out of the rule for a guard arriving somewhere, run it
again, and read what TLC reports.
