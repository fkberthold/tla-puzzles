------------------------------ MODULE Scaffold ------------------------------
(***************************************************************************)
(* Half of the multi-module fixture for harness/test-spike-measure.sh.      *)
(*                                                                          *)
(* This stands in for the shape the isolation spike used, where the model   *)
(* the learner writes extends a scaffolding module that carries most of the *)
(* state. The measurement tool read only the named module and reported one  *)
(* variable for a six-variable model, so the fixture pins the closure.      *)
(*                                                                          *)
(* Two variables here, one in Extender.tla, so a correct reading is 3       *)
(* variables over 2 modules.                                                *)
(***************************************************************************)
EXTENDS Naturals

VARIABLES tick, phase

ScaffoldInit == tick = 0 /\ phase = "start"

ScaffoldStep ==
  /\ tick < 2
  /\ tick' = tick + 1
  /\ phase' = "running"

=============================================================================
