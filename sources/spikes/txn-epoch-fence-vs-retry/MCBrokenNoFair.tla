--------------------------- MODULE MCBrokenNoFair ---------------------------
(***************************************************************************)
(* THE MISTAKE, RUN ON PURPOSE.  The same liveness property against Spec    *)
(* rather than FairSpec.                                                   *)
(*                                                                         *)
(* It also exits 13, and its counterexample is worthless: a behaviour that  *)
(* stops one step in, while actions are still enabled.  Both runs are kept  *)
(* so the difference is a measurement rather than an assertion.            *)
(*                                                                         *)
(* Expect exit 13, on a SHORTER trace than MCBrokenLiveness.               *)
(***************************************************************************)
EXTENDS TxnBroken

=============================================================================
