------------------------------- MODULE Concrete -------------------------------
(***************************************************************************)
(* THE CLAIM THAT IS NOT A CHECK (V2-PLAN.md section 10).                   *)
(*                                                                          *)
(* The concrete spec is the WRONG one -- `Untick` is back, so the mapped    *)
(* level falls and the refinement genuinely does not hold. The author       *)
(* believes they have said so to TLC, by writing                            *)
(*                                                                          *)
(*     THEOREM Spec => A!Spec                                               *)
(*                                                                          *)
(* TLC SILENTLY IGNORES THEOREM. It is documentation for TLAPS and carries  *)
(* no obligation whatsoever into a model check. With no PROPERTY in the     *)
(* .cfg, TLC reports "No error has been found" on a spec that is provably   *)
(* wrong.                                                                   *)
(*                                                                          *)
(* There is deliberately no `Refines` operator here. A submission whose     *)
(* refinement claim lives ONLY in a THEOREM is rejected on inspection, and  *)
(* the shape of the mistake -- an unchecked implication into another        *)
(* module's Spec -- is what refinement.sh matches on.                       *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE ticks

vars == << ticks >>

Init == ticks = 0
Tick   == ticks < 6 /\ ticks' = ticks + 1
Untick == ticks >= 3 /\ ticks' = ticks - 3
Next == Tick \/ Untick

Spec == Init /\ [][Next]_vars

A == INSTANCE Abstract WITH level <- (ticks \div 3)

THEOREM Spec => A!Spec

===============================================================================
