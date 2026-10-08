-------------------------- MODULE MCFenceRotates16 --------------------------
(* The repaired spec at MaxEpoch = 16, which is the row that matters for    *)
(* cost: a counterexample stops breadth-first search early, a PROOF does    *)
(* not. Expect exit 0. *)
EXTENDS TxnFenceRotates

=============================================================================
