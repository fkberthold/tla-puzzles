--------------------------- MODULE PostOfficePass ---------------------------
\* A variant: N passes through by name instead of being substituted. The
\* guard is still not checked, so it is the instance and not the arithmetic
\* that loses it.
EXTENDS Naturals

CONSTANT N

VARIABLES occupied, open

B == INSTANCE LockerBank WITH used <- occupied

Init == B!Init /\ open = FALSE

Shutter == open' = ~open /\ UNCHANGED occupied

Next ==
    \/ B!Next /\ UNCHANGED open
    \/ Shutter

Spec == Init /\ [][Next]_<<occupied, open>>

NeverOver == B!NeverOver

=============================================================================
