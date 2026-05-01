---- MODULE CounterA ----
EXTENDS Integers

CONSTANT Max
ASSUME Max \in Nat /\ Max >= 1

VARIABLE n

vars == << n >>

Init == n = 0
Inc   == n < Max /\ n' = n + 1
Reset == n = Max /\ n' = 0
Next  == Inc \/ Reset
Spec  == Init /\ [][Next]_vars

TypeOK == n \in 0..Max

====
