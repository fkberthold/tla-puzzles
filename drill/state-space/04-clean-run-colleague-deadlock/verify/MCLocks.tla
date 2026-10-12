----------------------------- MODULE MCLocks -----------------------------
EXTENDS Locks

CONSTANTS a, b, l1, l2

\* Named in a .cfg as CONSTANT Order <- OppositeOrder, or <- SameOrder.
OppositeOrder == [w \in {a, b} |-> IF w = a THEN <<l1, l2>> ELSE <<l2, l1>>]
SameOrder == [w \in {a, b} |-> <<l1, l2>>]

==========================================================================
