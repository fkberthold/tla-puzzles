# The dive

Four divers go down as a group. Before the dive each diver checks in with
the leader, in any order. Only when every diver has checked in may anyone
go down, and then they go down one at a time. Any diver still on the
surface can call the dive off at any time. Once anyone has called it off,
nobody else goes down. The divers already down carry on, and a diver who is
down can't call anything off.

Rules:

1. Nobody is down before everyone has checked in.
2. No diver is ever both down and calling the dive off.

Write the specification from an empty file, with both rules as named checks,
and run it with four divers. A correct model finds 321 distinct states.

Then let a checked-in diver go down without waiting for the rest, run it
again, and read what TLC reports.
