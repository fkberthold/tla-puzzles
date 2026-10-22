---- MODULE Quantify ----
EXTENDS Integers
VARIABLE s

Init == s = {}
Grow == s = {} /\ s' = {1}
Next == Grow
Spec == Init /\ [][Next]_<<s>>

\* Every element is negative.
AllNeg == \A x \in s : x < 0

\* Some element is negative.
SomeNeg == \E x \in s : x < 0
==========================
