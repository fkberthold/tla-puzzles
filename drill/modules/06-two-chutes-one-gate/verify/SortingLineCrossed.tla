------------------------- MODULE SortingLineCrossed -------------------------
\* The other wrong neighbour: each rule wired to the other chute's variable.
\* Every instance is happy with itself. Only a property written from
\* outside the instances notices.
EXTENDS Naturals

CONSTANTS Parcels, Small

VARIABLES light, paired

L == INSTANCE Chute WITH Admit <- LAMBDA p : p <= Small, passed <- paired
P == INSTANCE Chute WITH Admit <- LAMBDA p : p % 2 = 0, passed <- light

Init == L!Init /\ P!Init

Next ==
    \/ L!Next /\ UNCHANGED light
    \/ P!Next /\ UNCHANGED paired

Spec == Init /\ [][Next]_<<light, paired>>

OnlyAdmitted == L!OnlyAdmitted /\ P!OnlyAdmitted

Routed ==
    /\ \A p \in light : p <= Small
    /\ \A p \in paired : p % 2 = 0

=============================================================================
