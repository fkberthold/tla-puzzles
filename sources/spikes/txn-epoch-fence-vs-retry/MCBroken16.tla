----------------------------- MODULE MCBroken16 -----------------------------
(* The liveness check at MaxEpoch = 16. Short.MaxValue is 32767 in the real *)
(* coordinator, so the question this row answers is whether the counter's   *)
(* range is a cost axis at all. Expect exit 13. *)
EXTENDS TxnBroken

=============================================================================
