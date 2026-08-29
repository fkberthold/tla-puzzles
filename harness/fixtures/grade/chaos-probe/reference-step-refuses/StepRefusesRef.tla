------------------------- MODULE StepRefusesRef -------------------------
(***************************************************************************)
(* The reference spec for `chaos-probe/reference-step-refuses`. Byte for    *)
(* byte the same system as the package next door, under a different module  *)
(* name.                                                                    *)
(*                                                                          *)
(* Holding the system fixed across the two references is what isolates the  *)
(* variable. The specs agree, the submission is the same file, and the only *)
(* thing that moves is what the obligations can say. One package is refused *)
(* and one grades.                                                          *)
(*                                                                          *)
(* Reference package interface:                                             *)
(*   this module            Spec, Observe                                   *)
(*   StepRefusesRefObl.tla  ObsDomain, Req_*(o), Step_*(o, p), Landmark_*(o)*)
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
