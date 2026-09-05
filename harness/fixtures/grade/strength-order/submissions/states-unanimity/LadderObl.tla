--------------------------- MODULE LadderObl ---------------------------
(***************************************************************************)
(* THE ANSWER KEY, stated as the learner states it: one requirement over    *)
(* the observation, and nothing else in the submission moves.               *)
(*                                                                          *)
(* It says what LadderRefObl!Req_unanimity says. Read as a constraint on    *)
(* the spec the learner was handed, it cuts that spec down to exactly the   *)
(* reference behaviour, so this submission is the one that should pass.     *)
(*                                                                          *)
(* The sibling `states-at-least-two/` states a strict weakening under the   *)
(* SAME operator name. The name is shared on purpose. It leaves the text of *)
(* the requirement as the only difference between the two verdict objects,  *)
(* so a grader that reports the same thing for both is reporting nothing    *)
(* about the answer.                                                        *)
(***************************************************************************)
EXTENDS Naturals

Req_answer(o) == o.issued => o.approvals = 3

=============================================================================
