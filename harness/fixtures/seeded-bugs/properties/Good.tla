-------------------------------- MODULE Good --------------------------------
(***************************************************************************)
(* A SUBMISSION THAT PASSES THE MATRIX.                                     *)
(*                                                                          *)
(* Logically equivalent to the oracle, written differently on purpose:      *)
(* a subset test instead of two membership tests, and an implication        *)
(* instead of a negated conjunction.  If the matrix only accepted the       *)
(* oracle's own text it would be testing string equality, and it would      *)
(* penalise exactly the representational freedom §3.2 exists to protect.    *)
(*                                                                          *)
(* Under the type conjunct, `ns = "green" => ew = "red"` and                *)
(* `~(ns = "green" /\ ew = "green")` pick out the same states, because      *)
(* `ew` ranges over a two-element set.                                      *)
(***************************************************************************)
EXTENDS Crossing

Inv == /\ {ns, ew} \subseteq Colors
       /\ (ns = "green" => ew = "red")

=============================================================================
