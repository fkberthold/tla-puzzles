---- MODULE UndoTailPop ----
\* Wrong neighbour: undo written with the one removal operator the module
\* hands you, which takes from the front. It undoes the oldest edit. The
\* type invariant cannot see it. Row 5 of the table can.
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
  /\ hist' = Tail(hist)

Next == (\E e \in Edits : Edit(e)) \/ Undo

Spec == Init /\ [][Next]_vars
====
