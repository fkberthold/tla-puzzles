---- MODULE DeskSeqStaysOut ----
\* Wrong neighbour in the list encoding: Return puts the book on the desk
\* and forgets to take it off the loan set. The rule fails on the first
\* return, and if it were not checked, the same book would be returned
\* twice and the desk would hold it twice.
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
  /\ desk' = Append(desk, b)
  /\ UNCHANGED out

Shelve == \E i \in DOMAIN desk :
  /\ desk' = SubSeq(desk, 1, i - 1) \o SubSeq(desk, i + 1, Len(desk))
  /\ UNCHANGED out

Next == (\E b \in Books : Borrow(b) \/ Return(b)) \/ Shelve

Spec == Init /\ [][Next]_vars

NeverBoth == \A i \in DOMAIN desk : desk[i] \notin out

NoBookTwice == \A i, j \in DOMAIN desk : i /= j => desk[i] /= desk[j]
====
