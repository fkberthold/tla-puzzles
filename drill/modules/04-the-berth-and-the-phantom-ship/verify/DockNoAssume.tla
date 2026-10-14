--------------------------- MODULE DockNoAssume ---------------------------
\* The same dock with the assumption deleted. Nothing else differs.
CONSTANTS Ships, Empty

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
