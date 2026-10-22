---- MODULE OneTank ----
EXTENDS Integers
VARIABLE level
vars == <<level>>

T1 == INSTANCE Tank WITH Capacity <- 3, tank <- level
T2 == INSTANCE Tank WITH Capacity <- 3, tank <- level

Init == T1!Init /\ T2!Init
Next == T1!Next \/ T2!Next
Spec == Init /\ [][Next]_vars
========================
