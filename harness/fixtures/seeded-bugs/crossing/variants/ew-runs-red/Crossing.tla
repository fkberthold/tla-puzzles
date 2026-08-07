------------------------------ MODULE Crossing ------------------------------
(***************************************************************************)
(* SEEDED VARIANT: ew-runs-red.  WRONG ON PURPOSE.                          *)
(*                                                                          *)
(* The mirror image of ns-runs-red: EWGo has lost its `ns = "red"` conjunct.*)
(* (green,red) --EWGo--> (green,green).                                     *)
(*                                                                          *)
(* Present so that "catches the mutual-exclusion bug" is not satisfiable by *)
(* a property that only ever looks at one of the two lights.                *)
(***************************************************************************)
EXTENDS Naturals

VARIABLES ns, ew

vars == << ns, ew >>

Colors == {"red", "green"}

Init == ns = "red" /\ ew = "red"

NSGo   == ns = "red"   /\ ew = "red" /\ ns' = "green" /\ ew' = ew
NSStop == ns = "green" /\ ns' = "red"   /\ ew' = ew
EWGo   == ew = "red"   /\ ew' = "green" /\ ns' = ns
EWStop == ew = "green" /\ ew' = "red"   /\ ns' = ns

Next == NSGo \/ NSStop \/ EWGo \/ EWStop

Spec == Init /\ [][Next]_vars

Code(c) == IF c = "green" THEN 1 ELSE IF c = "red" THEN 0 ELSE 9

Alias == [ north |-> Code(ns), east |-> Code(ew) ]

=============================================================================
