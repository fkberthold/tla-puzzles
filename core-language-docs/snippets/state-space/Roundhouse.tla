---- MODULE Roundhouse ----
EXTENDS Integers
VARIABLE bay

\* These bounds are the wrong way round, which is what Charter assumes against.
Inverted == INSTANCE Charter WITH Lo <- 9, Hi <- 1

Init == bay = 0
Shunt == bay < 2 /\ bay' = bay + 1
Parked == bay = 2 /\ UNCHANGED bay
Next == Shunt \/ Parked
Spec == Init /\ [][Next]_<<bay>>

Reached == bay <= 2
Sane == Inverted!Width >= 0
===========================
