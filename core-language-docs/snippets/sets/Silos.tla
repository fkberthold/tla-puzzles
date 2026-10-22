---- MODULE Silos ----
EXTENDS Integers, FiniteSets
VARIABLE open

Bins == 1..4

Init == open = {}
Fill == \E b \in Bins \ open : open' = open \cup {b}
Next == Fill
Spec == Init /\ [][Next]_<<open>>

Shape == open \in SUBSET Bins
Doubling == Cardinality(SUBSET Bins) = 16
OneMoreBin == Cardinality(SUBSET (1..5)) = 2 * Cardinality(SUBSET Bins)

Still == UNCHANGED open
SpecPower == open \in SUBSET Bins /\ [][Still]_<<open>>
SpecSubseteq == open \subseteq Bins /\ [][Still]_<<open>>
======================
