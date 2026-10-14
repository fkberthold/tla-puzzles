---- MODULE RobotRef ----
\* Reference answer. A cell is a pair, the record is a list of pairs, and
\* the robot is wherever the record ends. Indexing a pair and indexing the
\* record are the same operation, because a pair is a sequence of length 2.
EXTENDS Naturals, Sequences

Cells == (1..3) \X (1..3)

VARIABLE path

vars == <<path>>

Here == path[Len(path)]

Adjacent(a, b) ==
  \/ a[1] = b[1] /\ (a[2] = b[2] + 1 \/ b[2] = a[2] + 1)
  \/ a[2] = b[2] /\ (a[1] = b[1] + 1 \/ b[1] = a[1] + 1)

Visited(c) == \E i \in DOMAIN path : path[i] = c

TypeOK ==
  /\ path \in Seq(Cells)
  /\ Len(path) \in 1..9

Init == \E c \in Cells : path = <<c>>

Step == \E c \in Cells :
  /\ Adjacent(Here, c)
  /\ ~Visited(c)
  /\ path' = Append(path, c)

Lift == \E c \in Cells : path' = <<c>>

Next == Step \/ Lift

Spec == Init /\ [][Next]_vars

\* Every move in the record is to a cell that shares a side with the one
\* before it. The range stops one short of the end on purpose.
NeighboursOnly == \A i \in 1..(Len(path) - 1) : Adjacent(path[i], path[i + 1])

NoCellTwice == \A i, j \in DOMAIN path : i /= j => path[i] /= path[j]
====
