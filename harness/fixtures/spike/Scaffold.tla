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
(*                                                                          *)
(* The keyword sits alone on its line ON PURPOSE. A parser that strips      *)
(* VARIABLES off its own line and then falls back to re-reading that line   *)
(* counts the keyword itself as a variable and reports 4. The fencing spike *)
(* hit exactly that on a 7-variable model.                                  *)
(***************************************************************************)
EXTENDS Naturals

VARIABLES
  tick, phase

ScaffoldInit == tick = 0 /\ phase = "start"

ScaffoldStep ==
  /\ tick < 2
  /\ tick' = tick + 1
  /\ phase' = "running"

=============================================================================
