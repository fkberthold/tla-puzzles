---- MODULE NoArith ----
EXTENDS Sequences
VARIABLE q

Init == q = <<>>
Push == q' = Append(q, Len(q) + 1)
Next == Push
Spec == Init /\ [][Next]_<<q>>

Cap == Len(q) <= 2
========================
