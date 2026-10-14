---- MODULE RobotDomainEdge ----
\* Wrong neighbour: the adjacency rule quantified over the whole domain.
\* At the last index it asks for path[Len(path) + 1], which does not exist,
\* and TLC stops the first time it evaluates the invariant.
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

NeighboursOnly == \A i \in DOMAIN path : Adjacent(path[i], path[i + 1])

NoCellTwice == \A i, j \in DOMAIN path : i /= j => path[i] /= path[j]
====
