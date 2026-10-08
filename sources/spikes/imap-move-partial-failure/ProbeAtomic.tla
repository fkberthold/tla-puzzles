---------------------------- MODULE ProbeAtomic ----------------------------
(***************************************************************************)
(* Vacuity probes for MoveAtomic, which passes all three clauses.           *)
(*                                                                          *)
(* A passing run proves nothing if the interesting states are unreachable.   *)
(* Every definition here is a claim I expect TLC to REFUTE, so rc 12 is the  *)
(* good outcome and rc 0 is the finding.                                     *)
(*                                                                          *)
(* Kept in its own module so the server models stay free of anything a       *)
(* reader could mistake for a requirement.                                   *)
(***************************************************************************)
EXTENDS MoveAtomic

\* Refuted means: messages really do leave the source mailbox, so the three
\* clauses did not hold by nothing ever happening.
AllStayInSource == \A m \in Msg : loc[m] = {Source}

\* Refuted means: the target mailbox really does get populated.
NothingReachesTarget == \A m \in Msg : Target \notin loc[m]

\* Refuted means: the command really does answer.
CommandNeverReplies == resp = "open"

\* Refuted means: the tagged NO branch really fires.
NeverRepliesNo == resp # "no"

(***************************************************************************)
(* THE PROBE THAT CHECKS THE MODELLING CHOICE.                              *)
(*                                                                          *)
(* The RFC says nothing about what the server does with the rest of the set *)
(* after one message fails, and the choice recorded in MoveBase is that the  *)
(* rest may still be attempted. That choice is only real if a mixed outcome  *)
(* is reachable: one message finished and left behind, another finished and  *)
(* moved. A model that stops at the first failure cannot reach it, and the   *)
(* reachable outcomes there are prefixes of the set.                         *)
(*                                                                          *)
(* Refuted means the model admits the wider set and the choice is in the     *)
(* spec rather than only in the comment.                                     *)
(***************************************************************************)
NoMixedOutcome ==
    ~ \E a, b \in Msg : /\ a # b
                        /\ a \notin pending
                        /\ b \notin pending
                        /\ loc[a] = {Source}
                        /\ loc[b] = {Target}

(***************************************************************************)
(* The last sentence of the paragraph: "This is true even if the server      *)
(* returns a tagged NO response to the command." Refuted means a tagged NO   *)
(* can follow real movement, so a client that reads NO as "nothing           *)
(* happened" is wrong.                                                       *)
(***************************************************************************)
NoMeansNothingHappened ==
    (resp = "no") => (\A m \in Msg : loc[m] = {Source})

(***************************************************************************)
(* THIS ONE I EXPECT TO HOLD, and it is here to be reported rather than      *)
(* refuted. RFC 9051 section 6.4.8 says "the \Deleted flag MUST NOT be set   *)
(* for any message", so the conforming server leaves `flagged` constantly    *)
(* FALSE. That makes `flagged` a frozen variable in this model, which is     *)
(* vacuity vector 5, and the honest reading is that the requirement is what  *)
(* froze it. Reported in REPORT.md rather than hidden.                       *)
(***************************************************************************)
NoDeletedFlagEverSet == \A m \in Msg : ~flagged[m]

===========================================================================
