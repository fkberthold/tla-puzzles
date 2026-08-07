----------------------------- MODULE AlwaysTrue -----------------------------
(***************************************************************************)
(* THE SUBMISSION THE WHOLE COMPONENT EXISTS TO REJECT.                     *)
(*                                                                          *)
(* `Inv == TRUE` holds of the reference.  It holds of every seeded variant. *)
(* It is non-vacuous by §5.3's measure -- the state space is healthy, an    *)
(* INVARIANT really is configured, and every action fires.  It survives the *)
(* comment gate, it type-checks, and TLC exits 0 on it every single time.   *)
(*                                                                          *)
(* Every check that asks "does your property hold?" says yes.  The seeded-  *)
(* bug matrix is the only one that asks the other question -- "does it ever *)
(* say no?" -- and it is the only mechanical defense against this.          *)
(*                                                                          *)
(* Expected: PROPERTY_TOO_WEAK (40), on the FIRST variant, having exited 0  *)
(* where 12 was required.                                                   *)
(***************************************************************************)
EXTENDS Crossing

Inv == TRUE

=============================================================================
