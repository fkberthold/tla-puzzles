------------------------------- MODULE Concrete -------------------------------
(***************************************************************************)
(* REGRESSION CASE FOR A FALSE POSITIVE, found by running refinement.sh    *)
(* over the shipped puzzle corpus.                                          *)
(*                                                                          *)
(* The mapping below is correct and fully stated. It is only WRAPPED: the   *)
(* definition head, the INSTANCE and the WITH sit on three lines. A line-   *)
(* by-line matcher sees `A ==` with no INSTANCE on it, fails to find the    *)
(* instance at all, and then reports a stated mapping as an implicit one.   *)
(*                                                                          *)
(* That is a wrong verdict on a correct submission -- the refusal firing on *)
(* the thing it exists to encourage. Wrong in the safe direction, but wrong.*)
(* refinement.sh reassembles each definition onto one logical line before   *)
(* matching anything, so this fixture must come out REFINES.                *)
(*                                                                          *)
(* The wrap is not hypothetical: two puzzles already on main                *)
(* (T59-tier6-capstone-two-level-refinement, C02-cross-tier-capstone) put   *)
(* their WITH clauses across several lines.                                 *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE ticks

vars == << ticks >>

Init == ticks = 0
Tick == ticks < 6 /\ ticks' = ticks + 1
Next == Tick

Spec == Init /\ [][Next]_vars

A ==
  INSTANCE Abstract
    WITH level <- (ticks \div 3)

Refines ==
  A!Spec

===============================================================================
