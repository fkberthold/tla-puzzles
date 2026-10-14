-------------------------- MODULE SortingLineNamed --------------------------
\* The same line with each rule defined first and substituted by name.
EXTENDS Naturals

CONSTANTS Parcels, Small

VARIABLES light, paired

IsLight(p) == p <= Small
IsEven(p) == p % 2 = 0

L == INSTANCE Chute WITH Admit <- IsLight, passed <- light
P == INSTANCE Chute WITH Admit <- IsEven, passed <- paired

Init == L!Init /\ P!Init

Next ==
    \/ L!Next /\ UNCHANGED paired
    \/ P!Next /\ UNCHANGED light

Spec == Init /\ [][Next]_<<light, paired>>

OnlyAdmitted == L!OnlyAdmitted /\ P!OnlyAdmitted

Routed ==
    /\ \A p \in light : p <= Small
    /\ \A p \in paired : p % 2 = 0

=============================================================================
