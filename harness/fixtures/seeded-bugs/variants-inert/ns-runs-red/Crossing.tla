------------------------------ MODULE Crossing ------------------------------
(***************************************************************************)
(* SEEDED VARIANT: ns-runs-red, again.  WRONG ON PURPOSE.                   *)
(*                                                                          *)
(* Byte-identical in effect to crossing/variants/ns-runs-red/, and present  *)
(* here only so the inert matrix is a MIXED set: one live variant and one   *)
(* inert one.  A matrix whose only variant were the inert one would leave   *)
(* "reports VARIANT_INERT" indistinguishable from "reports VARIANT_INERT    *)
(* whenever it cannot catch anything".                                      *)
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
