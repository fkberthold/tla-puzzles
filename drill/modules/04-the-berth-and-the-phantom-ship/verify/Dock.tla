------------------------------- MODULE Dock -------------------------------
\* One berth. A ship moors when the berth is empty, and a ship that has
\* just left may not moor again until some other ship has been in.
CONSTANTS Ships, Empty

ASSUME Empty \notin Ships

VARIABLES berth, last

TypeOK ==
    /\ berth \in Ships \cup {Empty}
    /\ last \in Ships \cup {Empty}

Init == berth = Empty /\ last = Empty

Moor(s) ==
    /\ berth = Empty
    /\ s /= last
    /\ berth' = s
    /\ UNCHANGED last

Leave ==
    /\ berth \in Ships
    /\ berth' = Empty
    /\ last' = berth

Next == (\E s \in Ships : Moor(s)) \/ Leave

Spec == Init /\ [][Next]_<<berth, last>>

SomeoneCanMoor == berth = Empty => \E s \in Ships : s /= last

=============================================================================
