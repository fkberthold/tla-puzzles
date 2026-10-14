---- MODULE Gap ----
\* A broken corridor. Same as Corridor except the next tile starts one cell
\* past the end of the one before it, so a cell is skipped between tiles.
EXTENDS Claims

vars == <<size, next, laid>>

Init ==
  /\ size \in 1..4
  /\ next = 1
  /\ laid = {}

Lay ==
  /\ next <= Wall
  /\ laid' = laid \cup Here!Cells
  /\ next' = next + size + 1
  /\ UNCHANGED size

Next == Lay

Spec == Init /\ [][Next]_vars
====
