----------------------------- MODULE MutexOnly -----------------------------
(***************************************************************************)
(* A SUBMISSION THAT CATCHES SOME VARIANTS AND NOT ALL OF THEM.             *)
(*                                                                          *)
(* Mutual exclusion, stated correctly and stated alone.  It catches         *)
(* ns-runs-red and ew-runs-red -- the two variants that put both lights     *)
(* green -- and it is silent on amber-on-go, where the lights are never     *)
(* both green and the defect is that one of them is not a light colour at   *)
(* all.                                                                     *)
(*                                                                          *)
(* This is the row that makes "passes the matrix" mean something.  A        *)
(* submission can be genuinely, non-trivially right about one bug and still *)
(* not be strong enough, and the matrix has to be able to say so -- with    *)
(* the specific variant named, because "your invariant is too weak" on its  *)
(* own is not feedback anyone can act on.                                   *)
(***************************************************************************)
EXTENDS Crossing

Inv == ~(ns = "green" /\ ew = "green")

=============================================================================
