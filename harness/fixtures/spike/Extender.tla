------------------------------ MODULE Extender ------------------------------
(***************************************************************************)
(* The other half of the multi-module fixture. EXTENDS Scaffold, which      *)
(* declares two variables, and adds one of its own.                         *)
(*                                                                          *)
(* A correct measurement reads 3 variables over 2 modules. Reading this      *)
(* file alone gives 1, which is the defect this fixture exists to catch.    *)
(***************************************************************************)
EXTENDS Scaffold

VARIABLE count

vars == << tick, phase, count >>

Init == ScaffoldInit /\ count = 0

Step ==
  /\ ScaffoldStep
  /\ count' = count + 1

Spec == Init /\ [][Step]_vars

CountTracksTick == count = tick

=============================================================================
