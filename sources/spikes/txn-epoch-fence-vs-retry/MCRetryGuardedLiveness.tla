---------------------- MODULE MCRetryGuardedLiveness ------------------------
(* The third liveness-can-pass check. TxnRetryGuarded makes the retry       *)
(* predicate agree with the ending rule at the one value they disagreed on, *)
(* which repairs BOTH the liveness property and the invariant, and still    *)
(* closes the system at the ceiling. Expect exit 0. *)
EXTENDS TxnRetryGuarded

=============================================================================
