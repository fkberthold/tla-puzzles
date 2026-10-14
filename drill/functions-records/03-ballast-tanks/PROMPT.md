# Ballast tanks

A barge has three ballast tanks: fore, port and starboard. Each holds up
to 4 units of water. The barge was launched with 6 units aboard, 2 in each
tank. A pump moves water from any tank to any other tank, one unit at a
time, and water goes nowhere else: nothing is taken on and nothing is
discharged.

The gauges are read together, as one reading of all three tanks.

| reading (fore, port, starboard) | ever seen? |
|---|---|
| 4, 2, 0 | yes |
| 0, 3, 3 | yes |
| 5, 1, 0 | no |
| 2, 2, 1 | no |
| 3, 3, 1 | no |

Write the specification from an empty file. Say what the tanks can hold,
and state the rule that the last two rows break.

Check it with deadlock checking on. A correct model finds 19 distinct
states and reports no error.
