------------------------- MODULE AdmitsChaosRef -------------------------
(***************************************************************************)
(* The reference spec for `chaos-probe/reference-admits-chaos`. This is the *)
(* package the fixture exists to get REFUSED.                               *)
(*                                                                          *)
(* Nothing is wrong with this module. It is the lockbox again: a box holds  *)
(* zero to three parcels, one in or one out at a time, and the observation  *)
(* is honest about both. The defect lives next door in the obligations, and *)
(* it is worth keeping the spec ordinary so the fixture cannot be read as   *)
(* being about a strange reference model.                                   *)
(*                                                                          *)
(* Reference package interface, both halves required by harness/grade.sh:   *)
(*   this module            Spec, Observe                                   *)
(*   AdmitsChaosRefObl.tla  ObsDomain, Req_*(o) and Landmark_*(o)           *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE level

Init == level = 0

Fill  == level < 3 /\ level' = level + 1
Empty == level > 0 /\ level' = level - 1

Next == Fill \/ Empty

Spec == Init /\ [][Next]_level

Observe == [level |-> level, full |-> (level = 3)]

=============================================================================
