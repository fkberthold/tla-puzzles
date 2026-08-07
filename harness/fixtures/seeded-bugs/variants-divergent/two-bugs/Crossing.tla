------------------------------ MODULE Crossing ------------------------------
(***************************************************************************)
(* SEEDED VARIANT: two-bugs.  WRONG IN TWO INDEPENDENT WAYS.                *)
(*                                                                          *)
(*   NSGo   has lost its `ew = "red"` conjunct  -> (green,green) reachable  *)
(*   EWStop assigns "amber" instead of "red"    -> (red,amber)   reachable  *)
(*                                                                          *)
(* Both defects surface at the same BFS depth, in DIFFERENT states reached  *)
(* by DIFFERENT actions.  So a mutual-exclusion property and a type         *)
(* property both exit 12 on this variant while catching different bugs, and *)
(* the only thing that distinguishes them is the counterexample.            *)
(*                                                                          *)
(* This is the fixture for the trace comparison, and it is also why the     *)
(* comparison is not a pass/fail gate by default: BOTH properties are       *)
(* sound, BOTH are violated, and neither is wrong for firing where it does. *)
(***************************************************************************)
EXTENDS Naturals

VARIABLES ns, ew

vars == << ns, ew >>

Colors == {"red", "green"}

Init == ns = "red" /\ ew = "red"

NSGo   == ns = "red"   /\ ns' = "green" /\ ew' = ew
NSStop == ns = "green" /\ ns' = "red"   /\ ew' = ew
EWGo   == ew = "red"   /\ ns = "red" /\ ew' = "green" /\ ns' = ns
EWStop == ew = "green" /\ ew' = "amber" /\ ns' = ns

Next == NSGo \/ NSStop \/ EWGo \/ EWStop

Spec == Init /\ [][Next]_vars

Code(c) == IF c = "green" THEN 1 ELSE IF c = "red" THEN 0 ELSE 9

Alias == [ north |-> Code(ns), east |-> Code(ew) ]

=============================================================================
