---- MODULE Caliper ----
EXTENDS Integers
VARIABLE gauge

Lo == 3
Hi == 1
Band == Lo..Hi

Init == gauge \in Band
Next == gauge' = gauge
Spec == Init /\ [][Next]_<<gauge>>

Impossible == gauge /= gauge
========================
