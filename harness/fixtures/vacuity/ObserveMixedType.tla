-------------------------- MODULE ObserveMixedType --------------------------
(***************************************************************************)
(* One frozen field, and one LIVE field whose values are not all of the    *)
(* same type (bead tla-29m4).                                             *)
(*                                                                         *)
(* A per-field probe has to compare a field against something, and TLC     *)
(* does not return FALSE when the two sides are of different types -- it   *)
(* ABORTS the evaluation. So a field that holds a number in one phase of   *)
(* the run and a string in another can take the whole probe down with it,  *)
(* and a probe that dies reports nothing about the field NEXT to it. The   *)
(* frozen `ledger` here is that neighbour: it is the thing the gate exists *)
(* to find, and it is sitting behind the field most likely to break the    *)
(* instrument.                                                             *)
(*                                                                         *)
(* The heterogeneity lives in Observe rather than in a state variable on   *)
(* purpose. It is the OBSERVATION the probe reads, so that is where the    *)
(* hazard has to be for the fixture to exercise it, and it keeps Next free *)
(* of cross-type guards that would just move the same abort earlier.       *)
(***************************************************************************)
EXTENDS Naturals

VARIABLES tick, done
vars == <<tick, done>>

Init ==
    /\ tick = 0
    /\ done = FALSE

Advance == /\ done = FALSE
           /\ tick' = 1 - tick
           /\ done' = FALSE

Finish  == /\ done = FALSE
           /\ tick' = tick
           /\ done' = TRUE

Reopen  == /\ done = TRUE
           /\ tick' = tick
           /\ done' = FALSE

Next == Advance \/ Finish \/ Reopen

Spec == Init /\ [][Next]_vars

(***************************************************************************)
(* phase MOVES, and moves across a type boundary: 0, 1, and "closed".      *)
(* ledger is FROZEN, and is the field a working gate must still name.      *)
(***************************************************************************)
Observe ==
    [ phase  |-> IF done THEN "closed" ELSE tick,
      ledger |-> 0 ]

TypeOK ==
    /\ tick \in 0..1
    /\ done \in BOOLEAN

InitialObserve == [phase |-> 0, ledger |-> 0]

(* The naive per-field probe, compared against the initial value the way      *)
(* harness/refinement.sh:22-25 compares a mapping. It answers CORRECTLY on    *)
(* this fixture, at rc=12, and it answers correctly BY LUCK: phase leaves 0   *)
(* for 1 before it ever reaches "closed", so TLC stops at the violation and   *)
(* the cross-type comparison is never evaluated. The hazard is latent, not    *)
(* absent, which is why the fixture carries the probe below as well.          *)
MixedFieldProbePhase  == Observe.phase = InitialObserve.phase

(* The same comparison with the luck removed. True in both numeric states, so *)
(* evaluation MUST reach the string one -- and there it aborts rather than    *)
(* returning FALSE.                                                          *)
MixedCrossTypeProbe   == \/ Observe.phase = 0
                         \/ Observe.phase = 1

=============================================================================
