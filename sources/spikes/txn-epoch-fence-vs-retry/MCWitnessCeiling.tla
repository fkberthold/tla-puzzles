-------------------------- MODULE MCWitnessCeiling --------------------------
(* THE REACHABILITY CHECK the brief asks for by name. An off-by-one over a   *)
(* strictly increasing counter can be unreachable, so this asserts the       *)
(* counter never reaches MaxEpoch and requires TLC to refute it.             *)
(*                                                                          *)
(* rc=12 means the ceiling IS reachable and the defect is live.              *)
(* rc=0 would mean the whole family is dead and every other green run here   *)
(* means nothing.                                                           *)
EXTENDS TxnBroken

=============================================================================
