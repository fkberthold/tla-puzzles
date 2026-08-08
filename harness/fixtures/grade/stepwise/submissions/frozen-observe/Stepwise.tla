--------------------------- MODULE Stepwise ---------------------------
(***************************************************************************)
(* SUBMISSION: the observation never moves.                                 *)
(*                                                                          *)
(* THE TRAPDOOR INSIDE THE FIX. [][A]_Observe unfolds to                    *)
(* `A \/ UNCHANGED Observe`, so a spec whose observation is constant takes  *)
(* the second disjunct at every step and satisfies EVERY step obligation    *)
(* there is, vacuously and at rc=0. Measured. Adding two-state obligations  *)
(* to the grading engine would have bought nothing at all against this one, *)
(* and the frozen mapping is the exact hole the TLAiBench survey 6 records  *)
(* in the only public benchmark that grades TLA+ refinement.                *)
(*                                                                          *)
(* It also satisfies Req_capacity, since 3 is a permitted level. Both       *)
(* Adequacy members pass.                                                   *)
(*                                                                          *)
(* The landmark suite is what catches it, and this fixture is why           *)
(* grade.sh REQUIRES two pairwise-unsatisfiable landmarks of any problem    *)
(* that states a Step_* rather than recommending them. A frozen observation *)
(* is one value; one value cannot be both 3 and 0. Landmark_full is         *)
(* reached, Landmark_empty is not, and the submission is reported           *)
(* over-constrained.                                                        *)
(*                                                                          *)
(* Note what that means for a reference author: state a Step_* with one     *)
(* landmark and grade.sh refuses the PROBLEM, not the submission. The       *)
(* alternative is a problem that cannot catch the thing its own step        *)
(* obligation was added to catch.                                           *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE colour

Init == colour = "red"

Next == colour' \in {"red", "green"}

Spec == Init /\ [][Next]_colour

(***************************************************************************)
(* Both branches are 3. The operator READS the state, so TLC cannot         *)
(* constant-fold it and the non-vacuity probe passes -- this submission is  *)
(* graded, not refused as a config error.                                   *)
(***************************************************************************)
Observe == [level |-> IF colour = "red" THEN 3 ELSE 3]

=============================================================================
