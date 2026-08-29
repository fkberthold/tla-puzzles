----------------------- MODULE StepRefusesRefObl -----------------------
(***************************************************************************)
(* Obligations for `chaos-probe/reference-step-refuses`. The first of the   *)
(* two ways a package can survive the chaos probe, and the obvious one.     *)
(*                                                                          *)
(* Step_onestep is false of a chaos spec: chaos jumps from empty to full in *)
(* one step, and no pair of successive observations that far apart          *)
(* satisfies it. So the probe fails here, the package stands, and grade.sh  *)
(* goes on to grade the submission.                                         *)
(*                                                                          *)
(* THE TWO LANDMARKS ARE NOT OPTIONAL. Any module stating a Step_* owes     *)
(* grade.sh two or more pairwise-unsatisfiable landmarks, because           *)
(* [][A]_Observe unfolds to `A \/ UNCHANGED Observe` and a frozen           *)
(* observation satisfies every step obligation there is. One value cannot   *)
(* be both 3 and 0. That requirement predates this fixture and is checked   *)
(* separately.                                                              *)
(***************************************************************************)
EXTENDS Naturals, Integers

ObsDomain == [level: 0..3, full: BOOLEAN]

Req_capacity(o) == o.level \in 0..3

(***************************************************************************)
(* PHI_2 -- one parcel at a time, over a PAIR of successive observations.   *)
(* This is what the probe cannot satisfy.                                   *)
(***************************************************************************)
Step_onestep(o, p) == p.level - o.level \in {-1, 0, 1}

Landmark_full(o)  == o.level = 3
Landmark_empty(o) == o.level = 0

=============================================================================
