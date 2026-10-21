---- MODULE TwoExtends ----
EXTENDS Integers
EXTENDS Sequences
VARIABLE q

Init == q = 0
Next == q' = q + 1
Spec == Init /\ [][Next]_<<q>>

Cap == q <= 2
===========================
