-------------------------- MODULE MCBrokenLiveness --------------------------
(***************************************************************************)
(* THE HEADLINE RUN.  The requirement is liveness, so this is the config    *)
(* that reports the real failure.                                          *)
(*                                                                         *)
(* Checked against FairSpec, never Spec.  MCBrokenNoFair.cfg is the same   *)
(* property against the unfair spec, run on purpose so the useless         *)
(* counterexample is on the record next to the useful one.                 *)
(*                                                                         *)
(* Expect exit 13.                                                        *)
(***************************************************************************)
EXTENDS TxnBroken

=============================================================================
