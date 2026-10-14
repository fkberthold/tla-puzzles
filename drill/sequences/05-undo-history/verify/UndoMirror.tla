---- MODULE UndoMirror ----
\* Wrong neighbour: newest edit at the front, and the drop when full
\* written as a slice of the first three whether or not there are three.
\* SubSeq past the end of a list is not a truncation in TLC. It is an
\* error, and it fires on the first edit.
EXTENDS Naturals, Sequences

CONSTANT Edits

VARIABLE hist

vars == <<hist>>

TypeOK ==
  /\ hist \in Seq(Edits)
  /\ Len(hist) <= 3

Init == hist = <<>>

Edit(e) == hist' = SubSeq(<<e>> \o hist, 1, 3)

Undo ==
  /\ Len(hist) > 0
  /\ hist' = Tail(hist)

Next == (\E e \in Edits : Edit(e)) \/ Undo

Spec == Init /\ [][Next]_vars
====
