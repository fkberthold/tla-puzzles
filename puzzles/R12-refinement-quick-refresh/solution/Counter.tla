---- MODULE Counter ----
EXTENDS Naturals

CONSTANT Max

VARIABLE n

Init == n = 0

Tick == n' = n + 1 /\ n < Max

Next == Tick

vars == << n >>

Spec == Init /\ [][Next]_vars

TypeOK == n \in 0..Max

================================
