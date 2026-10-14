--------------------------- MODULE TankPairAnon ---------------------------
\* The wrong neighbour: both instances anonymous. Every name from the
\* second one lands on top of the first, and SANY only warns.
EXTENDS Naturals

CONSTANTS CapA, CapB

VARIABLES a, b

INSTANCE HeaderTank WITH Cap <- CapA, level <- a
INSTANCE HeaderTank WITH Cap <- CapB, level <- b

Spec == Init /\ [][Next]_<<a, b>>

=============================================================================
