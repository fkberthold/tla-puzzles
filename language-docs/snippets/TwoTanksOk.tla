---- MODULE TwoTanksOk ----
EXTENDS Integers
VARIABLES level1, level2
vars == <<level1, level2>>

T1 == INSTANCE Tank WITH Capacity <- 3, tank <- level1
T2 == INSTANCE Tank WITH Capacity <- 3, tank <- level2

Init == T1!Init /\ T2!Init
Next == (T1!Next /\ UNCHANGED level2) \/ (T2!Next /\ UNCHANGED level1)
Spec == Init /\ [][Next]_vars
===========================
