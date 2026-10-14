---------------------------- MODULE HeaderTank ----------------------------
EXTENDS Naturals

CONSTANT Cap

VARIABLE level

Init == level = 0

Fill == level < Cap /\ level' = level + 1

Drain == level > 0 /\ level' = 0

Next == Fill \/ Drain

Spec == Init /\ [][Next]_level

WithinCap == level <= Cap

=============================================================================
