---- MODULE RingCount ----
EXTENDS Integers

CONSTANT Max
ASSUME Max \in Nat /\ Max >= 1

VARIABLE rings

vars == << rings >>

Init == rings = 0
Ring == rings < Max /\ rings' = rings + 1
Next == Ring
Spec == Init /\ [][Next]_vars

TypeOK == rings \in 0..Max

====
