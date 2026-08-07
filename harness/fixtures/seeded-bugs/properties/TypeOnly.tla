----------------------------- MODULE TypeOnly ------------------------------
(***************************************************************************)
(* THE OTHER HALF OF THE ORACLE, ALONE.                                     *)
(*                                                                          *)
(* Catches amber-on-go, and is silent on both mutual-exclusion variants.    *)
(* Together with MutexOnly it shows that neither conjunct of the oracle     *)
(* subsumes the other -- the same disjointness argument §5.4 makes for its  *)
(* two guards.                                                              *)
(*                                                                          *)
(* Also the trace-comparison fixture.  Against variants-divergent/two-bugs  *)
(* this property and the oracle both exit 12, and they get there by         *)
(* different actions.                                                       *)
(***************************************************************************)
EXTENDS Crossing

Inv == {ns, ew} \subseteq Colors

=============================================================================
