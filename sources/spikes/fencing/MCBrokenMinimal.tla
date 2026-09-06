---------------------------- MODULE MCBrokenMinimal ----------------------------
(***************************************************************************)
(* The smallest bounded-clock model that still exhibits the bug: two       *)
(* clients, a one-tick lease, and a clock that stops at 1. One tick is     *)
(* the whole of the pause. Below this the lease never lapses and the       *)
(* invariant holds for the wrong reason.                                   *)
(***************************************************************************)
EXTENDS Broken

=============================================================================
