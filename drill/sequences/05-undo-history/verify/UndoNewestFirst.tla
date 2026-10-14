---- MODULE UndoNewestFirst ----
\* A correct editor written the other way round: newest edit at the
\* front. Undo is then the one removal operator the module hands you. It
\* is a fine spec of the editor and it does not admit the table, because
\* the table fixes which end is which.
EXTENDS Naturals, Sequences

CONSTANT Edits

VARIABLE hist

vars == <<hist>>

TypeOK ==
  /\ hist \in Seq(Edits)
  /\ Len(hist) <= 3

Init == hist = <<>>

Edit(e) ==
  hist' = IF Len(hist) = 3 THEN <<e>> \o SubSeq(hist, 1, 2) ELSE <<e>> \o hist

Undo ==
  /\ Len(hist) > 0
  /\ hist' = Tail(hist)

Next == (\E e \in Edits : Edit(e)) \/ Undo

Spec == Init /\ [][Next]_vars
====
