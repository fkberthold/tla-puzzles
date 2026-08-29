------------------------ MODULE StateRefusesRef ------------------------
(***************************************************************************)
(* The reference spec for `chaos-probe/reference-state-refuses`. The same   *)
(* system once more, under a third module name.                             *)
(*                                                                          *)
(* Reference package interface:                                             *)
(*   this module             Spec, Observe                                  *)
(*   StateRefusesRefObl.tla  ObsDomain, Req_*(o) and Landmark_*(o)          *)
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
