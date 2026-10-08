---------------------------- MODULE RelayVacuous ----------------------------
(***************************************************************************)
(* THE ROW THIS COMPONENT EXISTS FOR, IN ITS TEMPORAL FORM.                 *)
(*                                                                          *)
(* `Inv == TRUE` is the safety version: it holds of the reference, passes   *)
(* every vacuity probe, and catches nothing.  This is the same worthlessness *)
(* written as a temporal formula -- the position is always one of the three  *)
(* positions, for ever, in the reference and in both variants alike.        *)
(*                                                                          *)
(* It has to be TEMPORAL in shape rather than merely trivial, because a     *)
(* trivially true STATE predicate would be graded by the invariant channel  *)
(* and would say nothing about whether the temporal channel grades at all.  *)
(***************************************************************************)
EXTENDS Relay

Live == []<>(stage \in Stages)

=============================================================================
