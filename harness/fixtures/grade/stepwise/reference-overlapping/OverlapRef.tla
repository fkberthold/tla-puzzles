-------------------------- MODULE OverlapRef --------------------------
(***************************************************************************)
(* A MALFORMED PROBLEM PACKAGE, and the spec half of it is fine. The defect *)
(* is in OverlapRefObl.tla beside it.                                       *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE level

Init == level = 0

Fill  == level < 3 /\ level' = level + 1
Empty == level > 0 /\ level' = level - 1

Next == Fill \/ Empty

Spec == Init /\ [][Next]_level

Observe == [level |-> level]

=============================================================================
