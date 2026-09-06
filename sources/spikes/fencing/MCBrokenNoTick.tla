---------------------------- MODULE MCBrokenNoTick ----------------------------
(***************************************************************************)
(* The control for MCBrokenMinimal.tla. Same system with MaxTime = 0, so   *)
(* the clock cannot move and no lease can ever lapse. Exits 0, and that 0  *)
(* means the model is too small rather than the system being correct.      *)
(***************************************************************************)
EXTENDS Broken

=============================================================================
