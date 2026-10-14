---- MODULE Corridor ----
\* The real corridor. One tile length, picked when the job starts and never
\* changed, laid from the first cell on with each tile butted against the
\* last.
EXTENDS Claims

vars == <<size, next, laid>>

Init ==
  /\ size \in 1..4
  /\ next = 1
  /\ laid = {}

Lay ==
  /\ next <= Wall
  /\ laid' = laid \cup Here!Cells
  /\ next' = next + size
  /\ UNCHANGED size

Next == Lay

Spec == Init /\ [][Next]_vars
====
