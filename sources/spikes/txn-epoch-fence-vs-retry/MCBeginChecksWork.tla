------------------------- MODULE MCBeginChecksWork --------------------------
(* Work witness for TxnBeginChecks: the epoch does climb to the rotation    *)
(* threshold, so transactions really complete before the ceiling closes the *)
(* system. Expect exit 12. *)
EXTENDS TxnBeginChecks

=============================================================================
