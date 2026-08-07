------------------------------ MODULE Crossing ------------------------------
(***************************************************************************)
(* SEEDED VARIANT: inert-guard.  A MUTATION THAT CHANGES NOTHING.           *)
(*                                                                          *)
(* NSStop's guard `ns = "green"` has become `ns # "red"`.  That is a real   *)
(* single mutation of the kind a mutation tool emits, and it is a real      *)
(* relational-operator change -- and on this spec it is a NO-OP.  Every     *)
(* reachable state has ns \in {"red", "green"}, so `ns # "red"` and         *)
(* `ns = "green"` pick out exactly the same states.  The mutated spec's     *)
(* state graph is IDENTICAL to the reference's.                             *)
(*                                                                          *)
(* No property whatsoever can tell the two apart, because there is nothing  *)
(* to tell apart.  ~39.3% of single mutations are like this.                *)
(*                                                                          *)
(* The matrix must therefore report this as a defect in the VARIANT SET,    *)
(* not as a failure of the learner's property -- and it must reach that     *)
(* verdict without consulting the learner's property at all, which is why   *)
(* the oracle is run against every variant before any grading happens.      *)
(*                                                                          *)
(* Kept OUT of crossing/variants/ on purpose: an inert variant poisons the  *)
(* whole matrix it sits in, which is exactly the behaviour under test.      *)
(***************************************************************************)
EXTENDS Naturals

VARIABLES ns, ew

vars == << ns, ew >>

Colors == {"red", "green"}

Init == ns = "red" /\ ew = "red"

NSGo   == ns = "red"   /\ ew = "red" /\ ns' = "green" /\ ew' = ew
NSStop == ns # "red"   /\ ns' = "red"   /\ ew' = ew
EWGo   == ew = "red"   /\ ns = "red" /\ ew' = "green" /\ ns' = ns
EWStop == ew = "green" /\ ew' = "red"   /\ ns' = ns

Next == NSGo \/ NSStop \/ EWGo \/ EWStop

Spec == Init /\ [][Next]_vars

Code(c) == IF c = "green" THEN 1 ELSE IF c = "red" THEN 0 ELSE 9

Alias == [ north |-> Code(ns), east |-> Code(ew) ]

=============================================================================
