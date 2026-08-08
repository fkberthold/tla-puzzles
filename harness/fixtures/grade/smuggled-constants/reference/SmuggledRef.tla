------------------------- MODULE SmuggledRef -------------------------
(***************************************************************************)
(* The reference for the `smuggled-constants` fixture (bead tla-j8yd).      *)
(*                                                                          *)
(* The spec itself is the plain lockbox and carries no trick. The fixture   *)
(* lives in the constants.cfg beside it, which is the only text from a      *)
(* problem package that reaches a generated judge .cfg.                     *)
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
