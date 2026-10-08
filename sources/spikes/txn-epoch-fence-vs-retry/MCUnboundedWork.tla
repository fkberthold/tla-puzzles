-------------------------- MODULE MCUnboundedWork ---------------------------
(* Work witness for the unbounded control: the counter really does climb    *)
(* inside the constraint, so TxnUnbounded.cfg's exit 0 is not the           *)
(* clean-because-nothing-moves result. Expect exit 12. *)
EXTENDS TxnUnbounded

=============================================================================
