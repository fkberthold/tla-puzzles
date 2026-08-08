------------------------- MODULE FlipAwayFromB ------------------------------
(* Witnesses that a day scheduled to B can end up with A. MUST FAIL: rc=12.  *)
EXTENDS MCCustody

BKeepsEveryScheduledDay ==
    \A d \in Days : Sched(d) = B => Observe.custodian[d] = B

=============================================================================
