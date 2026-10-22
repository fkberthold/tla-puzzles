---- MODULE Lathe ----
EXTENDS Integers, FiniteSets
VARIABLE order

Lengths == {2, 5, 9}
Slots == 1..3

Arrangements == [Slots -> Lengths]
Ascending == {f \in Arrangements : \A i \in 1..2 : f[i] < f[i+1]}

Init == order \in Ascending
Next == UNCHANGED order
Spec == Init /\ [][Next]_<<order>>

Candidates == Cardinality(Arrangements) = 27
ExactlyOne == Cardinality(Ascending) = 1
Sorted == \A i \in 1..2 : order[i] < order[i+1]
======================
