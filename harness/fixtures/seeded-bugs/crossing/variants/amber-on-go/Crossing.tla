------------------------------ MODULE Crossing ------------------------------
(***************************************************************************)
(* SEEDED VARIANT: amber-on-go.  WRONG ON PURPOSE.                          *)
(*                                                                          *)
(* NSGo assigns "amber", a value outside Colors.  (red,red) --NSGo-->       *)
(* (amber,red), which then has no successor at all.                         *)
(*                                                                          *)
(* THIS IS THE DISCRIMINATING ROW.  Mutual exclusion never fires on it --   *)
(* the two lights are never both green -- so a submission that states only  *)
(* mutual exclusion passes ns-runs-red and ew-runs-red and fails here.      *)
(* Without a variant of this shape "catches the seeded bugs" would be       *)
(* satisfiable by a single conjunct.                                        *)
(*                                                                          *)
(* The dead end is deliberate and harmless: verdict.sh runs with deadlock   *)
(* checking OFF by default, so TLC reports the invariant violation rather   *)
(* than the missing successor.                                              *)
(***************************************************************************)
EXTENDS Naturals

VARIABLES ns, ew

vars == << ns, ew >>

Colors == {"red", "green"}

Init == ns = "red" /\ ew = "red"

NSGo   == ns = "red"   /\ ew = "red" /\ ns' = "amber" /\ ew' = ew
NSStop == ns = "green" /\ ns' = "red"   /\ ew' = ew
EWGo   == ew = "red"   /\ ns = "red" /\ ew' = "green" /\ ns' = ns
EWStop == ew = "green" /\ ew' = "red"   /\ ns' = ns

Next == NSGo \/ NSStop \/ EWGo \/ EWStop

Spec == Init /\ [][Next]_vars

Code(c) == IF c = "green" THEN 1 ELSE IF c = "red" THEN 0 ELSE 9

Alias == [ north |-> Code(ns), east |-> Code(ew) ]

=============================================================================
