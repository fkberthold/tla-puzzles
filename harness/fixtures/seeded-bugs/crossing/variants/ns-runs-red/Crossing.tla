------------------------------ MODULE Crossing ------------------------------
(***************************************************************************)
(* SEEDED VARIANT: ns-runs-red.  WRONG ON PURPOSE.                          *)
(*                                                                          *)
(* NSGo has lost its `ew = "red"` conjunct, so north-south turns green      *)
(* without looking at east-west.  (red,green) --NSGo--> (green,green).      *)
(*                                                                          *)
(* Caught by any property that states mutual exclusion.  NOT caught by a    *)
(* type invariant alone -- both lights still hold values in Colors.         *)
(***************************************************************************)
EXTENDS Naturals

VARIABLES ns, ew

vars == << ns, ew >>

Colors == {"red", "green"}

Init == ns = "red" /\ ew = "red"

NSGo   == ns = "red"   /\ ns' = "green" /\ ew' = ew
NSStop == ns = "green" /\ ns' = "red"   /\ ew' = ew
EWGo   == ew = "red"   /\ ns = "red" /\ ew' = "green" /\ ns' = ns
EWStop == ew = "green" /\ ew' = "red"   /\ ns' = ns

Next == NSGo \/ NSStop \/ EWGo \/ EWStop

Spec == Init /\ [][Next]_vars

Code(c) == IF c = "green" THEN 1 ELSE IF c = "red" THEN 0 ELSE 9

Alias == [ north |-> Code(ns), east |-> Code(ew) ]

=============================================================================
