---------------------------- MODULE RelayUnsound ----------------------------
(***************************************************************************)
(* A TEMPORAL SUBMISSION THE REFERENCE ITSELF VIOLATES.                     *)
(*                                                                          *)
(* The relay never reaches position 5, so this is false of the correct      *)
(* specification.  It would also "catch" every variant, which is the mirror *)
(* image of RelayVacuous and exactly as worthless -- hence PHASE 2, which   *)
(* runs before any variant is touched.                                      *)
(*                                                                          *)
(* The row it pins is narrower than that: rc=13 in PHASE 2 has to reach     *)
(* PROPERTY_UNSOUND.  A script whose refutation code is 12 passes this      *)
(* through as LIVENESS_VIOLATION instead, which tells the learner TLC's     *)
(* exit code where it could have told them their property is wrong.         *)
(***************************************************************************)
EXTENDS Relay

Live == []<>(stage = 5)

=============================================================================
