---- MODULE Counter ----
EXTENDS Integers

CONSTANT Max
ASSUME Max \in Nat /\ Max >= 1

VARIABLE n

vars == << n >>

Init == n = 0
Inc == n < Max /\ n' = n + 1
Next == Inc
Spec == Init /\ [][Next]_vars

TypeOK == n \in 0..Max

====
