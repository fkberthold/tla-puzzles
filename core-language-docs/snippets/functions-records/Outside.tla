---- MODULE Outside ----
EXTENDS Integers, Sequences
VARIABLE q

Init == q = <<10, 20>>
Next == UNCHANGED q
Spec == Init /\ [][Next]_<<q>>

\* Reading one past the end. The same out-of-domain index that EXCEPT
\* dropped in silence stops the run here.
Past == q[Len(q) + 1] = 0
=======================
