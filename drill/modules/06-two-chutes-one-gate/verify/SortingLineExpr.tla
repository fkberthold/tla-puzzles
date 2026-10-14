-------------------------- MODULE SortingLineExpr --------------------------
\* The wrong neighbour: a boolean expression where an operator is wanted.
EXTENDS Naturals

CONSTANTS Parcels, Small

VARIABLES light, paired

L == INSTANCE Chute WITH Admit <- (p <= Small), passed <- light
P == INSTANCE Chute WITH Admit <- (p % 2 = 0), passed <- paired

Init == L!Init /\ P!Init

Next ==
    \/ L!Next /\ UNCHANGED paired
    \/ P!Next /\ UNCHANGED light

Spec == Init /\ [][Next]_<<light, paired>>

OnlyAdmitted == L!OnlyAdmitted /\ P!OnlyAdmitted

=============================================================================
