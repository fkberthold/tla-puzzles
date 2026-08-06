------------------------------- MODULE Abstract -------------------------------
(***************************************************************************)
(* The abstract spec every refinement fixture is checked against: a         *)
(* three-position level that only ever climbs, and stops at 2.              *)
(*                                                                          *)
(* Chosen so that a wrong concrete spec can actually be WRONG. An abstract  *)
(* with a single boolean variable is useless here: `lampOn' = ~lampOn`      *)
(* means every mapped step that changes anything is a legal step, so every  *)
(* concrete spec refines it and the refinement channel proves nothing. A    *)
(* monotone counter has a direction, so `broken/` can go the wrong way.     *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE level

vars == << level >>

Init == level = 0
Up   == level < 2 /\ level' = level + 1
Next == Up

Spec == Init /\ [][Next]_vars

===============================================================================
