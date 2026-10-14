----------------------------- MODULE TankPair -----------------------------
EXTENDS Naturals

CONSTANTS CapA, CapB

VARIABLES a, b

A == INSTANCE HeaderTank WITH Cap <- CapA, level <- a
B == INSTANCE HeaderTank WITH Cap <- CapB, level <- b

Init == A!Init /\ B!Init

\* One hose: a step is one tank's step, the other tank holds still.
Next ==
    \/ A!Next /\ UNCHANGED b
    \/ B!Next /\ UNCHANGED a

Spec == Init /\ [][Next]_<<a, b>>

WithinCap == A!WithinCap /\ B!WithinCap

=============================================================================
