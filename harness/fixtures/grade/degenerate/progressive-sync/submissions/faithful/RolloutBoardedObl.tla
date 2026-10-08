--------------------- MODULE RolloutBoardedObl ---------------------
(***************************************************************************)
(* The degenerate model's own requirements, which are the statement's       *)
(* requirements 1 and 3 rendered over Observe. Both are true of the         *)
(* faithful region as well, so obligation 2 passes on both and the          *)
(* Relational suite rests on the landmarks alone.                            *)
(*                                                                          *)
(* The district order is written out here rather than read from a constant, *)
(* for the same reason the reference obligations write theirs out: the      *)
(* Relational runs EXTEND the reference spec beside this module.             *)
(***************************************************************************)
EXTENDS Naturals, Sequences

Plan     == <<{"b1"}, {"b2"}>>
PlanLast == Len(Plan)

Req_signoff_says_what_it_means(o) ==
  \A k \in o.signedOff : \A b \in Plan[k] : o.working[b] = o.amendment

Req_one_district_at_a_time(o) ==
  \A b \in o.underIssue :
     /\ o.inHand \in 1 .. PlanLast
     /\ b \in Plan[o.inHand]

=============================================================================
