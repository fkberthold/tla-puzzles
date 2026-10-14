---- MODULE DeskSeq ----
\* Second encoding: the desk is a list in return order. The order is extra
\* state the prompt never asked for, and it shows up in the count.
EXTENDS Naturals, Sequences

CONSTANT Books

VARIABLES out, desk

vars == <<out, desk>>

OnDesk(b) == \E i \in DOMAIN desk : desk[i] = b

TypeOK ==
  /\ out \subseteq Books
  /\ desk \in Seq(Books)

Init ==
  /\ out = {}
  /\ desk = <<>>

Borrow(b) ==
  /\ b \notin out
  /\ ~OnDesk(b)
  /\ out' = out \cup {b}
  /\ UNCHANGED desk

Return(b) ==
  /\ b \in out
  /\ out' = out \ {b}
  /\ desk' = Append(desk, b)

Shelve == \E i \in DOMAIN desk :
  /\ desk' = SubSeq(desk, 1, i - 1) \o SubSeq(desk, i + 1, Len(desk))
  /\ UNCHANGED out

Next == (\E b \in Books : Borrow(b) \/ Return(b)) \/ Shelve

Spec == Init /\ [][Next]_vars

NeverBoth == \A i \in DOMAIN desk : desk[i] \notin out

\* A set cannot hold a book twice. A list can, so this has to be said.
NoBookTwice == \A i, j \in DOMAIN desk : i /= j => desk[i] /= desk[j]
====
