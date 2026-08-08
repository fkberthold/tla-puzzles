------------------------- MODULE FlipAwayFromA ------------------------------
(* Witnesses that a day scheduled to A can end up with B. MUST FAIL: rc=12.  *)
EXTENDS MCCustody

AKeepsEveryScheduledDay ==
    \A d \in Days : Sched(d) = A => Observe.custodian[d] = A

=============================================================================
