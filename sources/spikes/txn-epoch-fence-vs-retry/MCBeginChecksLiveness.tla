----------------------- MODULE MCBeginChecksLiveness ------------------------
(***************************************************************************)
(* The second liveness-can-pass check, and the interesting one.            *)
(*                                                                         *)
(* TxnBeginChecks repairs the LIVENESS property and leaves the defect's own *)
(* invariant false: EndRetry still hands the client an exhausted epoch, the *)
(* client simply cannot start a transaction with it. So this exits 0 while  *)
(* TxnBeginChecks.cfg exits 12 on the same spec.                           *)
(*                                                                         *)
(* That is the measurement that says which of the two properties is the     *)
(* real requirement. See REPORT.md.                                        *)
(*                                                                         *)
(* Expect exit 0, and read it next to MCBeginChecksWork.cfg -- the repaired *)
(* system stops accepting new transactions once the ceiling is reached, so  *)
(* its exit 0 is partly the clean-because-idle hazard.                     *)
(***************************************************************************)
EXTENDS TxnBeginChecks

=============================================================================
