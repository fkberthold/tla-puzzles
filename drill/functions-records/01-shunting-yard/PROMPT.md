# The shunting yard

A goods yard has four tracks and three wagons. Each wagon stands on one
track. The yard's one rule: two wagons never stand on the same track.

The yard can open the day with the wagons on any tracks the rule allows.
During the day a shunter moves one wagon at a time onto a track with
nothing on it.

Write the specification from an empty file. Say what the one variable can
be, say where the day can start, and state the rule.

Check it with tracks 1 to 4 and wagons a, b and c, with deadlock checking
on. A correct model finds 24 distinct states and reports no error.

Then say, without running it, what the checker would do if the line that
says where the day starts and the line that says what the variable can be
swapped their shapes.
