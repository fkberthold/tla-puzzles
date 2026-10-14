---------------------------- MODULE LockerBank ----------------------------
\* The shared library. A bank of N lockers, counted rather than named.
EXTENDS Naturals

CONSTANT N

ASSUME N >= 1

VARIABLE used

Init == used = 0

Deposit == used < N /\ used' = used + 1

Collect == used > 0 /\ used' = used - 1

Next == Deposit \/ Collect

Spec == Init /\ [][Next]_used

NeverOver == used <= N

=============================================================================
