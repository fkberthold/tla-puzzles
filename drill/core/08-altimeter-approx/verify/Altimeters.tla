---- MODULE Altimeters ----
\* Reference answer. Agreement within tolerance is a user-defined
\* infix operator, and the fault lamp is pinned to it with an iff.
EXTENDS Integers

CONSTANTS Tol, Span

VARIABLES a, b, fault

vars == <<a, b, fault>>

x \approx y == x - y <= Tol /\ y - x <= Tol

Readings == -Span..Span

TypeOK ==
  /\ a \in Readings
  /\ b \in Readings
  /\ fault \in BOOLEAN

Init ==
  /\ a = 0
  /\ b = 0
  /\ fault = FALSE

DriftA ==
  /\ \E d \in {-1, 1} :
       /\ a + d \in Readings
       /\ a' = a + d
  /\ fault' = ~(a' \approx b)
  /\ UNCHANGED b

DriftB ==
  /\ \E d \in {-1, 1} :
       /\ b + d \in Readings
       /\ b' = b + d
  /\ fault' = ~(a \approx b')
  /\ UNCHANGED a

Resync ==
  /\ fault
  /\ b' = a
  /\ fault' = FALSE
  /\ UNCHANGED a

Next == DriftA \/ DriftB \/ Resync

Spec == Init /\ [][Next]_vars

FaultIffDisagree == fault <=> ~(a \approx b)
====
