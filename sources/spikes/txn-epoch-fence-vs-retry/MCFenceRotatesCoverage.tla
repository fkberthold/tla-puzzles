----------------------- MODULE MCFenceRotatesCoverage -----------------------
(* The vacuity target for the repaired spec. Its rc=0 on the liveness        *)
(* property is the strongest claim in this spike, so it is the model that    *)
(* most needs a dead-action probe behind it: a guard that silently shut an   *)
(* action off would make that rc=0 mean nothing. Expect exit 0. *)
EXTENDS TxnFenceRotates

=============================================================================
