------------------------- MODULE PostOfficeGuarded -------------------------
\* The fix. The client restates the guard on the value it actually passes.
EXTENDS Naturals

CONSTANTS Lockers, Reserved

ASSUME Lockers - Reserved >= 1

VARIABLES occupied, open

B == INSTANCE LockerBank WITH N <- Lockers - Reserved, used <- occupied

Init == B!Init /\ open = FALSE

Shutter == open' = ~open /\ UNCHANGED occupied

Next ==
    \/ B!Next /\ UNCHANGED open
    \/ Shutter

Spec == Init /\ [][Next]_<<occupied, open>>

NeverOver == B!NeverOver

=============================================================================
