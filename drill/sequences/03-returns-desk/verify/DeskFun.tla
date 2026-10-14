---- MODULE DeskFun ----
\* Third encoding: one function from book to place. A book has one place
\* by construction, so the rule the prompt asks for has nothing left to
\* say and the type invariant is the whole of it.
EXTENDS Naturals

CONSTANT Books

VARIABLE place

vars == <<place>>

Places == {"shelf", "out", "desk"}

TypeOK == place \in [Books -> Places]

Init == place = [b \in Books |-> "shelf"]

Borrow(b) ==
  /\ place[b] = "shelf"
  /\ place' = [place EXCEPT ![b] = "out"]

Return(b) ==
  /\ place[b] = "out"
  /\ place' = [place EXCEPT ![b] = "desk"]

Shelve(b) ==
  /\ place[b] = "desk"
  /\ place' = [place EXCEPT ![b] = "shelf"]

Next == \E b \in Books : Borrow(b) \/ Return(b) \/ Shelve(b)

Spec == Init /\ [][Next]_vars
====
