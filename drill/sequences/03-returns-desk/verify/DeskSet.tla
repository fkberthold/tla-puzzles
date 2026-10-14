---- MODULE DeskSet ----
\* First encoding: the desk is a set. Nothing about the prompt asks for an
\* order, and a set is the shape that holds no order.
EXTENDS Naturals

CONSTANT Books

VARIABLES out, desk

vars == <<out, desk>>

TypeOK ==
  /\ out \subseteq Books
  /\ desk \subseteq Books

Init ==
  /\ out = {}
  /\ desk = {}

Borrow(b) ==
  /\ b \notin out
  /\ b \notin desk
  /\ out' = out \cup {b}
  /\ UNCHANGED desk

Return(b) ==
  /\ b \in out
  /\ out' = out \ {b}
  /\ desk' = desk \cup {b}

Shelve(b) ==
  /\ b \in desk
  /\ desk' = desk \ {b}
  /\ UNCHANGED out

Next == \E b \in Books : Borrow(b) \/ Return(b) \/ Shelve(b)

Spec == Init /\ [][Next]_vars

NeverBoth == out \cap desk = {}
====
