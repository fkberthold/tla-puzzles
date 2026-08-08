---------------------- MODULE OneLandmarkRefObl ----------------------
(***************************************************************************)
(* A MALFORMED PROBLEM PACKAGE: a step obligation with ONE landmark.        *)
(*                                                                          *)
(* Everything here is individually reasonable, which is what makes it worth *)
(* a fixture. The requirement is well stated, the landmark is a real        *)
(* observation the spec reaches, and a reference author writing this would  *)
(* have no reason to suspect anything.                                      *)
(*                                                                          *)
(* What it cannot do is refuse a frozen observation. [][A]_Observe is       *)
(* satisfied vacuously by a submission whose observation never moves, and a *)
(* single landmark is reachable by a constant observation pinned at 3. So   *)
(* this package would grade a frozen submission a clean PASS on the very    *)
(* obligation it added Step_onestep to check.                               *)
(*                                                                          *)
(* grade.sh refuses the PACKAGE for it -- exit 2, attributed to the author, *)
(* never a verdict about a submission.                                      *)
(***************************************************************************)
EXTENDS Naturals, Integers

Req_capacity(o) == o.level \in 0..3

Step_onestep(o, p) == p.level - o.level \in {-1, 0, 1}

Landmark_full(o) == o.level = 3

=============================================================================
