-------------------------- MODULE LockboxRefObl --------------------------
(***************************************************************************)
(* The reference obligations for `lockbox`: the conjuncts PHI_i of          *)
(* V2-PLAN.md 5.2 obligation 1, plus the landmark observations of the       *)
(* Relational suite.                                                        *)
(*                                                                          *)
(* VARIABLE-FREE BY CONSTRUCTION. Every operator takes the observation      *)
(* record `o` as an argument and mentions no state variable. That is what   *)
(* lets harness/grade.sh EXTEND this module beside a SUBMISSION's spec,     *)
(* whose variables are its own business, and evaluate a reference           *)
(* requirement over the submission's states.                                *)
(*                                                                          *)
(* NAMES IN THIS FILE ARE NEVER EMITTED. grade.sh reports each obligation   *)
(* under an opaque digest (`R-xxxxxx`); the leak gate refuses to print a    *)
(* verdict object containing any identifier that occurs here and not in the *)
(* submission. See V2-PLAN.md 6b.1 and 6b.2.                                *)
(***************************************************************************)
EXTENDS Naturals

(***************************************************************************)
(* PHI_1 -- the lockbox never holds more than three parcels.                *)
(***************************************************************************)
Req_capacity(o) == o.level =< 3

(***************************************************************************)
(* PHI_2 -- the lockbox never holds a negative number of parcels. Distinct  *)
(* from PHI_1, and separately creditable: a submission that gets the cap    *)
(* wrong can still get this one right, which is where per-conjunct partial  *)
(* credit comes from.                                                       *)
(***************************************************************************)
Req_floor(o) == o.level >= 0

(***************************************************************************)
(* LANDMARK -- an observation the reference reaches, so a submission must   *)
(* reach it too.                                                            *)
(*                                                                          *)
(* This is the Relational suite's answer to over-constraint BY OMISSION: a  *)
(* submission that simply leaves a transition out declares no requirement   *)
(* for `PHI => psi_j` to refute, so obligation 2 alone would pass it. The   *)
(* landmark is checked by refutation -- grade.sh requires the submission to *)
(* VIOLATE `~Landmark_full(Observe)`, exactly the rc=12 idiom of 5.5.       *)
(***************************************************************************)
Landmark_full(o) == o.level = 3

=============================================================================
