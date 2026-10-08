----------------------------- MODULE WeakTrue -----------------------------
(***************************************************************************)
(* A PROPERTY THAT SAYS NOTHING, submitted to watch the matrix say no.      *)
(*                                                                          *)
(* `Inv == TRUE` holds of the reference, holds of every variant, and passes  *)
(* every other check in the harness: the state space is healthy, an          *)
(* INVARIANT really is configured, and every action fires. The seeded-bug    *)
(* matrix is the only component that can refuse it, so a BUGS_CAUGHT on the  *)
(* real property means nothing until this one has been seen to fail.         *)
(*                                                                          *)
(* Expected verdict: PROPERTY_TOO_WEAK at rc 40.                             *)
(***************************************************************************)
EXTENDS MoveAtomic

Inv == TRUE

===========================================================================
