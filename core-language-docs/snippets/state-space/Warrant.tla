---- MODULE Warrant ----
EXTENDS Integers
CONSTANT Seats
ASSUME Seats \in Nat /\ Seats > 0

VARIABLE taken

Init == taken = 0
Seat == taken < Seats /\ taken' = taken + 1
Full == taken = Seats /\ UNCHANGED taken
Next == Seat \/ Full
Spec == Init /\ [][Next]_<<taken>>

Fits == taken <= Seats
========================
