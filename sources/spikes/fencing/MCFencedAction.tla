--------------------------- MODULE MCFencedAction ---------------------------
(***************************************************************************)
(* The FENCED system checked against the brief's literal wording.          *)
(*                                                                         *)
(* Fenced.cfg checks NoStaleWrite and exits 0. This checks NoExpiredWrite, *)
(* which says no accepted write came from an expired lease, and it FAILS.  *)
(*                                                                         *)
(* That is not a hole in the fence. A client whose lease lapsed while nobody *)
(* else wanted it still holds the highest token issued, so its write is    *)
(* accepted, and no correctness requirement is broken by that. The literal *)
(* wording is simply stronger than what fencing buys. See REPORT.md.       *)
(***************************************************************************)
EXTENDS Fenced

=============================================================================
