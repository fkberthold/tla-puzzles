---- MODULE RobotFromStart ----
\* Wrong neighbor: the move is checked against the first cell in the
\* record rather than the last. The first index is the one a reader reaches
\* for by reflex, and the adjacency rule catches it on the second move.
EXTENDS Naturals, Sequences

Cells == (1..3) \X (1..3)

VARIABLE path

vars == <<path>>

Adjacent(a, b) ==
  \/ a[1] = b[1] /\ (a[2] = b[2] + 1 \/ b[2] = a[2] + 1)
  \/ a[2] = b[2] /\ (a[1] = b[1] + 1 \/ b[1] = a[1] + 1)

Visited(c) == \E i \in DOMAIN path : path[i] = c

TypeOK ==
  /\ path \in Seq(Cells)
  /\ Len(path) \in 1..9

Init == \E c \in Cells : path = <<c>>

Step == \E c \in Cells :
  /\ Adjacent(path[1], c)
  /\ ~Visited(c)
  /\ path' = Append(path, c)

Lift == \E c \in Cells : path' = <<c>>

Next == Step \/ Lift

Spec == Init /\ [][Next]_vars

NeighborsOnly == \A i \in 1..(Len(path) - 1) : Adjacent(path[i], path[i + 1])

NoCellTwice == \A i, j \in DOMAIN path : i /= j => path[i] /= path[j]
====
