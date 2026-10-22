---- MODULE Siding ----
EXTENDS Integers
VARIABLE wagons

Init == wagons = 3
Shunt == wagons > 0 /\ wagons' = wagons - 1
Next == Shunt
Spec == Init /\ [][Next]_<<wagons>>

\* The same system with the finish written in as a step that changes nothing.
Parked == wagons = 0 /\ UNCHANGED wagons
QuietNext == Shunt \/ Parked
QuietSpec == Init /\ [][QuietNext]_<<wagons>>

Emptied == wagons >= 0
=======================
