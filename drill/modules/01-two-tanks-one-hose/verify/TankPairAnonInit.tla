------------------------- MODULE TankPairAnonInit -------------------------
\* The same mistake with nothing of its own defined, so SANY only warns and
\* TLC gets as far as the first state.
EXTENDS Naturals

CONSTANTS CapA, CapB

VARIABLES a, b

INSTANCE HeaderTank WITH Cap <- CapA, level <- a
INSTANCE HeaderTank WITH Cap <- CapB, level <- b

=============================================================================
