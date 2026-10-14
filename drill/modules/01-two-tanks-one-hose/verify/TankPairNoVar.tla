-------------------------- MODULE TankPairNoVar --------------------------
\* The other wrong neighbor: the constant is substituted, the variable
\* is not, and the pair module has no variable called level to fall back on.
EXTENDS Naturals

CONSTANTS CapA, CapB

VARIABLES a, b

A == INSTANCE HeaderTank WITH Cap <- CapA
B == INSTANCE HeaderTank WITH Cap <- CapB

Init == A!Init /\ B!Init

Next == A!Next \/ B!Next

Spec == Init /\ [][Next]_<<a, b>>

=============================================================================
