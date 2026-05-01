---- MODULE CounterC ----
EXTENDS Integers

CONSTANT Max
ASSUME Max \in Nat /\ Max >= 1

VARIABLE n

vars == << n >>

Init == n = 0

Inc == n < Max /\ n' = n + 1

\* BUG: this resets from any positive n, not only from n = Max.
\* The abstract only allows reset from n = Max. Fix this guard.
Reset == n > 0 /\ n' = 0

Next == Inc \/ Reset
Spec == Init /\ [][Next]_vars

TypeOK == n \in 0..Max

L0 == INSTANCE CounterA WITH n <- n
Refines == L0!Spec

====
