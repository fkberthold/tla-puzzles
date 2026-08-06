------------------------------ MODULE Till ------------------------------
(***************************************************************************)
(* The abstract shop: one number, which goes up by one on every sale.      *)
(***************************************************************************)
EXTENDS Naturals

CONSTANT Max

VARIABLE takings
vars == << takings >>

Init == takings = 0

Ring ==
  /\ takings < Max
  /\ takings' = takings + 1

Next == Ring

Spec == Init /\ [][Next]_vars

MonotonicTakings == [][takings' >= takings]_vars
=========================================================================
