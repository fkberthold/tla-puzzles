------------------------ MODULE RolloutRefObl ------------------------
(***************************************************************************)
(* The reference obligations for the `progressive-sync` degenerate-model    *)
(* package. Variable-free by construction.                                  *)
(*                                                                          *)
(* Three of the statement's seven requirements are stated here: 1, 3 and 6. *)
(* Requirement 4 is the cap, and it is left out because this instance gives *)
(* it nothing to say. Both districts hold one box, so no cap of one can be  *)
(* exceeded, and an obligation nothing can falsify is a full mark on a      *)
(* question that was never put. Requirements 2, 5 and 7 are left out to     *)
(* keep the package cheap, not because anything is wrong with them.          *)
(*                                                                          *)
(* The district order lives in a local operator rather than in a CONSTANT,  *)
(* because the Adequacy runs EXTEND a submission's spec beside this module  *)
(* and a name declared in both would be ambiguous there.                     *)
(***************************************************************************)
EXTENDS Naturals, Sequences

ObsBoxes     == {"b1", "b2"}
ObsDistricts == <<{"b1"}, {"b2"}>>
ObsLast      == Len(ObsDistricts)

ObsDomain == [amendment:  0 .. 1,
              working:    [ObsBoxes -> 0 .. 1],
              inHand:     0 .. ObsLast + 1,
              underIssue: SUBSET ObsBoxes,
              signedOff:  SUBSET (1 .. ObsLast)]

(***************************************************************************)
(* PHI_1, requirement 1. A sign-off says what it means.                     *)
(*                                                                          *)
(* Chaos reaches a signed-off district whose box still works to the         *)
(* standing edition, so this is false there and the package stands.          *)
(***************************************************************************)
Req_signoff_means(o) ==
  \A k \in o.signedOff : \A b \in ObsDistricts[k] : o.working[b] = o.amendment

(***************************************************************************)
(* PHI_2, requirement 3. One district at a time, so no box is under issue   *)
(* before the circulation opens or after it ends.                           *)
(***************************************************************************)
Req_one_district(o) ==
  \A b \in o.underIssue :
     /\ o.inHand \in 1 .. ObsLast
     /\ b \in ObsDistricts[o.inHand]

(***************************************************************************)
(* PHI_3, requirement 6, over a pair of successive observations. The        *)
(* circulation never goes back.                                             *)
(***************************************************************************)
Step_never_back(o, p) ==
  /\ o.signedOff \subseteq p.signedOff
  /\ p.inHand >= o.inHand

(***************************************************************************)
(* THE TWO LANDMARKS. A Step_* obliges the package to two that no single    *)
(* observation satisfies together, and these two disagree about whether     *)
(* anything is under issue.                                                 *)
(*                                                                          *)
(* Landmark_pasted_under_issue IS THE ONE THAT CATCHES THE DEGENERATE       *)
(* MODEL. A box has pasted the amendment in and is still out, because she   *)
(* has not read its line yet. Under the amended rule 4 that reading is      *)
(* where every circulation passes, and it is the reading the boardless      *)
(* model cannot produce: there the paste and the close are one step, so the *)
(* two conditions are never true at the same moment.                         *)
(***************************************************************************)
Landmark_pasted_under_issue(o) ==
  /\ o.amendment # 0
  /\ \E b \in o.underIssue : o.working[b] = o.amendment

Landmark_opening(o) ==
  /\ o.inHand = 0
  /\ o.underIssue = {}
  /\ o.signedOff = {}

=============================================================================
