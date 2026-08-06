--------------------------- MODULE LockboxRef ---------------------------
(***************************************************************************)
(* The reference spec PHI for the `lockbox` grading fixture.                *)
(*                                                                          *)
(* THE SYSTEM (this is what a problem statement would fix, V2-PLAN.md 3.2): *)
(* a lockbox holds between zero and three parcels. One parcel goes in or    *)
(* one comes out at a time. Nothing else happens.                           *)
(*                                                                          *)
(* THE REPRESENTATION IS THIS MODULE'S OWN CHOICE and carries no authority. *)
(* A submission is graded against the OBSERVATION (3.3), never against this *)
(* module's shape -- see the 3.5 note at the top of harness/grade.sh. The   *)
(* `correct-different` submission models the same system as a SET of parcel *)
(* tokens and must grade PASS.                                              *)
(*                                                                          *)
(* Reference package interface, both halves required by harness/grade.sh:   *)
(*   this module        Spec, Observe                                       *)
(*   LockboxRefObl.tla  Req_*(o) and Landmark_*(o), variable-free           *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE level

Init == level = 0

Fill   == level < 3 /\ level' = level + 1
Empty  == level > 0 /\ level' = level - 1

Next == Fill \/ Empty

Spec == Init /\ [][Next]_level

(***************************************************************************)
(* The observation operator. Grading keys off this and never off `level`.   *)
(***************************************************************************)
Observe == [level |-> level]

=============================================================================
