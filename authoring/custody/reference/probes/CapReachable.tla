-------------------------- MODULE CapReachable ------------------------------
(* Witnesses that N days can carry an agreed swap at once. MUST FAIL: rc=12. *)
EXTENDS MCCustody

CapNotReached ==
    Cardinality({d \in Days : Observe.custodian[d] # Sched(d)}) < N

=============================================================================
