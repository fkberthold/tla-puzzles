---- MODULE Dice ----
EXTENDS Integers

VARIABLES left, right

Faces == 1..6

TypeOK == left \in Faces /\ right \in Faces

Init ==
  /\ left \in Faces
  /\ right \in Faces

RerollLeft ==
  /\ left' \in Faces
  /\ right' = right

RerollRight ==
  /\ right' \in Faces
  /\ left' = left

Next == RerollLeft \/ RerollRight

Spec == Init /\ [][Next]_<<left, right>>
====
