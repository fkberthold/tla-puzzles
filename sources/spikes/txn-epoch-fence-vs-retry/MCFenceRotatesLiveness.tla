----------------------- MODULE MCFenceRotatesLiveness -----------------------
(***************************************************************************)
(* THE LIVENESS-CAN-PASS CHECK.                                            *)
(*                                                                         *)
(* A liveness property that only ever fails has not been shown to be        *)
(* checkable. This is the same property, the same fairness conjunct and the *)
(* same constant, against the repaired spec, and it has to come back clean  *)
(* or MCBrokenLiveness's exit 13 says nothing about the defect.            *)
(*                                                                         *)
(* Expect exit 0. Paired with MCFenceRotatesRotation.cfg, which proves the  *)
(* repaired system still does work rather than being clean by standing      *)
(* still.                                                                  *)
(***************************************************************************)
EXTENDS TxnFenceRotates

=============================================================================
