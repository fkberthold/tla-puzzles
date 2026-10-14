---- MODULE RobotRecord ----
\* Accepted variant: a cell as a record with x and y fields rather than a
\* pair. Nothing about the list changes. Only the way a cell is taken
\* apart does, and the state count is the same.
EXTENDS Naturals, Sequences

Cells == [x : 1..3, y : 1..3]

VARIABLE path

vars == <<path>>

Here == path[Len(path)]

Adjacent(a, b) ==
  \/ a.x = b.x /\ (a.y = b.y + 1 \/ b.y = a.y + 1)
  \/ a.y = b.y /\ (a.x = b.x + 1 \/ b.x = a.x + 1)

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

NeighboursOnly == \A i \in 1..(Len(path) - 1) : Adjacent(path[i], path[i + 1])

NoCellTwice == \A i, j \in DOMAIN path : i /= j => path[i] /= path[j]
====
