---- MODULE UndoRefuseFull ----
\* Wrong neighbor: a fourth edit is refused rather than pushing the
\* oldest out. Sound as a spec, wrong for this editor. Row 4 kills it.
EXTENDS Naturals, Sequences

CONSTANT Edits

VARIABLE hist

vars == <<hist>>

TypeOK ==
  /\ hist \in Seq(Edits)
  /\ Len(hist) <= 3

Init == hist = <<>>

Edit(e) ==
  /\ Len(hist) < 3
  /\ hist' = Append(hist, e)

Undo ==
  /\ Len(hist) > 0
  /\ hist' = SubSeq(hist, 1, Len(hist) - 1)

Next == (\E e \in Edits : Edit(e)) \/ Undo

Spec == Init /\ [][Next]_vars
====
