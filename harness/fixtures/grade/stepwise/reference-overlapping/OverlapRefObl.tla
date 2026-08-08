------------------------ MODULE OverlapRefObl ------------------------
(***************************************************************************)
(* A MALFORMED PROBLEM PACKAGE: a step obligation with two landmarks that   *)
(* OVERLAP.                                                                 *)
(*                                                                          *)
(* Counting landmarks is not enough, and this is the fixture that says so.  *)
(* There are two of them, both are real observations the spec reaches, and  *)
(* a package that only had to state "two or more" would be accepted.        *)
(*                                                                          *)
(* But level 3 satisfies both. A submission frozen at 3 reaches every       *)
(* landmark this module states, passes the whole Relational suite, and      *)
(* satisfies Step_onestep vacuously -- exactly the submission the landmark  *)
(* requirement exists to refuse. The guard is therefore pairwise            *)
(* UNSATISFIABILITY, checked with a real model-checking run over the        *)
(* reference rather than by counting.                                       *)
(***************************************************************************)
EXTENDS Naturals, Integers

Req_capacity(o) == o.level \in 0..3

Step_onestep(o, p) == p.level - o.level \in {-1, 0, 1}

Landmark_full(o) == o.level >= 3
Landmark_high(o) == o.level >= 2

=============================================================================
