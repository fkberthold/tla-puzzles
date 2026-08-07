------------------------------- MODULE Oracle -------------------------------
(***************************************************************************)
(* THE AUTHOR'S OWN PROPERTY -- the matrix's instrument, not a submission.  *)
(*                                                                          *)
(* seeded-bugs.sh runs this against the reference and against every variant *)
(* BEFORE it grades anything, for two reasons:                              *)
(*                                                                          *)
(*   1. Against the reference it must exit 0.  An oracle that the reference *)
(*      itself violates cannot certify anything, and the matrix says so     *)
(*      (ORACLE_UNSOUND) rather than grading with a broken instrument.      *)
(*                                                                          *)
(*   2. Against each variant it must exit 12.  A variant the ORACLE cannot  *)
(*      catch is one the harness has no witness for -- a semantically inert *)
(*      mutation.  ~39.3% of single mutations are inert, so this is the     *)
(*      common case, not the exotic one, and it is a defect in OUR variant  *)
(*      set rather than a failure of the learner's property.                *)
(***************************************************************************)
EXTENDS Crossing

Inv == /\ ns \in Colors
       /\ ew \in Colors
       /\ ~(ns = "green" /\ ew = "green")

=============================================================================
