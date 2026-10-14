---- MODULE UndoRef ----
\* Reference answer. The history is a list with both ends in play: edits
\* join at the back, undo takes from the back, and when a fourth edit
\* arrives the oldest leaves from the front.
EXTENDS Naturals, Sequences

CONSTANT Edits

VARIABLE hist

vars == <<hist>>

TypeOK ==
  /\ hist \in Seq(Edits)
  /\ Len(hist) <= 3

Init == hist = <<>>

Edit(e) ==
  hist' = IF Len(hist) = 3 THEN Append(Tail(hist), e) ELSE Append(hist, e)

Undo ==
  /\ Len(hist) > 0
  /\ hist' = SubSeq(hist, 1, Len(hist) - 1)

Next == (\E e \in Edits : Edit(e)) \/ Undo

Spec == Init /\ [][Next]_vars
====
