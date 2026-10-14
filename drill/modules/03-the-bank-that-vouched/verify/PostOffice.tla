---------------------------- MODULE PostOffice ----------------------------
\* The client. It owns the shutter and hands the bank a capacity it works
\* out from its own constants. The bank's guard on that capacity is not
\* checked through the instance, which is the point of the item.
EXTENDS Naturals

CONSTANTS Lockers, Reserved

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
