---------------------------- MODULE SortingLine ----------------------------
\* Two chutes from one module. Each rule is supplied in place, as a lambda.
\* Parcels passes through to both instances by name.
EXTENDS Naturals

CONSTANTS Parcels, Small

VARIABLES light, paired

L == INSTANCE Chute WITH Admit <- LAMBDA p : p <= Small, passed <- light
P == INSTANCE Chute WITH Admit <- LAMBDA p : p % 2 = 0, passed <- paired

Init == L!Init /\ P!Init

Next ==
    \/ L!Next /\ UNCHANGED paired
    \/ P!Next /\ UNCHANGED light

Spec == Init /\ [][Next]_<<light, paired>>

OnlyAdmitted == L!OnlyAdmitted /\ P!OnlyAdmitted

\* Stated from outside the instances, so a crossed wiring shows.
Routed ==
    /\ \A p \in light : p <= Small
    /\ \A p \in paired : p % 2 = 0

=============================================================================
