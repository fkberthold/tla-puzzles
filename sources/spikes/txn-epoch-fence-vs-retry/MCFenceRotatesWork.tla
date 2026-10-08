------------------------- MODULE MCFenceRotatesWork -------------------------
(* THE WORK WITNESS for the repaired spec, and it is the probe that stops   *)
(* MCFenceRotatesLiveness's exit 0 from being worthless. A coordinator that *)
(* accepted nothing would also report every transaction eventually ending.  *)
(*                                                                         *)
(* Asserts the epoch never climbs to the rotation threshold and requires    *)
(* TLC to refute it, so the counterexample is a run in which the normal end *)
(* path really fired. Expect exit 12.                                      *)
EXTENDS TxnFenceRotates

=============================================================================
