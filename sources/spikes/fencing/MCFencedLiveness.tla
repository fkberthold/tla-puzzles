---------------------------- MODULE MCFencedLiveness ----------------------------
(***************************************************************************)
(* Does anything here need fairness? One thing does, and it FAILS.         *)
(*                                                                         *)
(* Fencing is a safety mechanism and it is not free: a client that holds   *)
(* the lease can be superseded while it works and then refused. Checked    *)
(* against FairSpec so the counterexample is a real overtaking rather than *)
(* a behaviour that merely stopped. Expect exit 13.                        *)
(***************************************************************************)
EXTENDS Fenced

=============================================================================
