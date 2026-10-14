---- MODULE UndoAppendOnly ----
\* Wrong neighbour: edits join at the back and nothing ever leaves the
\* front. The history is four long after four edits, and the bound fails.
EXTENDS Naturals, Sequences

CONSTANT Edits

VARIABLE hist

vars == <<hist>>

TypeOK ==
  /\ hist \in Seq(Edits)
  /\ Len(hist) <= 3

Init == hist = <<>>

Edit(e) == hist' = Append(hist, e)

Undo ==
  /\ Len(hist) > 0
  /\ hist' = SubSeq(hist, 1, Len(hist) - 1)

Next == (\E e \in Edits : Edit(e)) \/ Undo

Spec == Init /\ [][Next]_vars
====
