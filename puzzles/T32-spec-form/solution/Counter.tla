---- MODULE Counter ----
EXTENDS Integers

VARIABLE count

vars == count

TypeOK == count \in 0..3

Init == count = 0

CountCar ==
  /\ count < 3
  /\ count' = count + 1

Reset ==
  /\ count = 3
  /\ count' = 0

Next == CountCar \/ Reset

EventuallyFull == <>(count = 3)

SpecNoFair == Init /\ [][Next]_vars

SpecFair == Init /\ [][Next]_vars /\ WF_vars(Next)
====
