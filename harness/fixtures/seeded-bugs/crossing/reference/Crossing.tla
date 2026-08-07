------------------------------ MODULE Crossing ------------------------------
(***************************************************************************)
(* THE REFERENCE SPEC for the seeded-bug matrix (V2-PLAN.md §5.5, bead     *)
(* tla-kl5.8).  A one-lane crossing: a north-south light and an east-west  *)
(* light, each red or green, and only one of them may be green at a time.  *)
(*                                                                          *)
(* Three reachable states -- (red,red), (green,red), (red,green) -- which   *)
(* is deliberate: every TLC run in the matrix has to be cheap, because the  *)
(* matrix runs 2 x (1 + N) of them.                                         *)
(*                                                                          *)
(* This module defines NO invariant.  The invariant is what the learner     *)
(* supplies, and the whole point of the matrix is to find out whether the   *)
(* one they supplied is strong enough to notice a broken crossing.  A       *)
(* module that shipped its own `Inv` would also collide with the learner's: *)
(* a property module EXTENDS this one, and redefining an inherited name is  *)
(* a SANY error, not a shadowing.                                           *)
(*                                                                          *)
(* Every seeded variant under ../variants/ is this file with ONE definition *)
(* changed, and keeps the module name `Crossing` so the same property       *)
(* module extends it unmodified.                                            *)
(***************************************************************************)
EXTENDS Naturals

VARIABLES ns, ew

vars == << ns, ew >>

Colors == {"red", "green"}

Init == ns = "red" /\ ew = "red"

NSGo   == ns = "red"   /\ ew = "red" /\ ns' = "green" /\ ew' = ew
NSStop == ns = "green" /\ ns' = "red"   /\ ew' = ew
EWGo   == ew = "red"   /\ ns = "red" /\ ew' = "green" /\ ns' = ns
EWStop == ew = "green" /\ ew' = "red"   /\ ns' = ns

Next == NSGo \/ NSStop \/ EWGo \/ EWStop

Spec == Init /\ [][Next]_vars

(***************************************************************************)
(* NORMALISATION FOR THE TRACE DUMP.                                        *)
(*                                                                          *)
(* seeded-bugs.sh passes this as `ALIAS Alias`, so the counterexample TLC   *)
(* dumps carries the normalised record and never the raw variables.  The    *)
(* normalisation happens BEFORE the dump, which is the only place it can    *)
(* happen: -dumpTrace writes whatever the alias says the state is.          *)
(*                                                                          *)
(* It lives in the SPEC, not in the learner's property module, because      *)
(* normalisation is the problem author's decision and because the oracle    *)
(* run and the learner run must normalise identically or the comparison     *)
(* means nothing.  A property module could not supply it to the oracle run  *)
(* at all.                                                                  *)
(*                                                                          *)
(* Note what is NOT done with it: the values below are never diffed.  Only  *)
(* the action-name sequence and the trace length are.  See the header of    *)
(* harness/seeded-bugs.sh for why.                                          *)
(***************************************************************************)
Code(c) == IF c = "green" THEN 1 ELSE IF c = "red" THEN 0 ELSE 9

Alias == [ north |-> Code(ns), east |-> Code(ew) ]

=============================================================================
