---- MODULE Lap ----
\* A broken corridor. Same as Corridor except the next tile starts on the
\* last cell of the one before it, so consecutive tiles overlap by a cell.
EXTENDS Claims

vars == <<size, next, laid>>

Init ==
  /\ size \in 1..4
  /\ next = 1
  /\ laid = {}

Lay ==
  /\ next <= Wall
  /\ laid' = laid \cup Here!Cells
  /\ next' = next + size - 1
  /\ UNCHANGED size

Next == Lay

Spec == Init /\ [][Next]_vars
====
