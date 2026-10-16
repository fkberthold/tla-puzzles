\* shunting -- a small yard. Three wagons, three tracks, and a parking that
\* is deliberately not uniform, so a rep that asks about one wagon's track
\* has a different answer from a rep that asks about another's.
\*
\* This is a FRAGMENT, not a module. No header, no EXTENDS, no trailing ====.
\* recall/recall.sh splices it verbatim between the fixed EXTENDS line and
\* Answer ==, so a file carrying its own header will not parse.
\*
\* Parking is written as a record literal on purpose: a record IS a function
\* whose domain is a set of strings, so DOMAIN Parking is Wagons, and the
\* reps that turn on that identity have somewhere to stand.
Wagons == {"a", "b", "c"}
Tracks == 1..3
Parking == [a |-> 1, b |-> 3, c |-> 3]
Train == <<"c", "a", "b">>
Capacity == 4
