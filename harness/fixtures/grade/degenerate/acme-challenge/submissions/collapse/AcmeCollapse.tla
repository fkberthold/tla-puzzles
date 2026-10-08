------------------------ MODULE AcmeCollapse ------------------------
(***************************************************************************)
(* THE DEGENERATE MODEL for `acme-challenge-retry-deadlock`: the collapse,  *)
(* where one act writes the defect entry and gives up. The retry loop never *)
(* turns, because the first failed visit refuses the man.                    *)
(*                                                                          *)
(* The step 5 reader measured it against all nine of the statement's        *)
(* requirements and got rc 0 over 16 distinct states at depth 5. Two        *)
(* further probes came back rc 0 as well, "no applicant ever carries more   *)
(* than one entry" and "no applicant ever stands under inspection carrying  *)
(* an entry". So a learner who collapses the two acts gets nine green       *)
(* checks over a model in which the office never goes back.                 *)
(*                                                                          *)
(* NOTHING IN THE RULES FORBIDS THE COLLAPSE. Rule 3 says the office can    *)
(* visit more than once, rule 5 says nothing forces a give-up, and rule 9   *)
(* relieves every act of obligation. All three are permissions, and no      *)
(* requirement of the nine is a reachability claim.                         *)
(***************************************************************************)
EXTENDS Naturals

Applicants == {"a1", "a2"}
Patience   == 2

VARIABLES standing, defects, givenUp

vars == <<standing, defects, givenUp>>

Init ==
  /\ standing = [a \in Applicants |-> "issued"]
  /\ defects  = [a \in Applicants |-> 0]
  /\ givenUp  = [a \in Applicants |-> FALSE]

SendWord(a) ==
  /\ standing[a] = "issued"
  /\ standing' = [standing EXCEPT ![a] = "inspecting"]
  /\ UNCHANGED <<defects, givenUp>>

VisitFinds(a) ==
  /\ standing[a] = "inspecting"
  /\ ~givenUp[a]
  /\ standing' = [standing EXCEPT ![a] = "allowed"]
  /\ UNCHANGED <<defects, givenUp>>

(***************************************************************************)
(* THE COLLAPSE. The entry and the give-up are one act, so a man never      *)
(* stands under inspection carrying an entry and the office never comes     *)
(* back to anybody.                                                         *)
(***************************************************************************)
FailAndGiveUp(a) ==
  /\ standing[a] = "inspecting"
  /\ ~givenUp[a]
  /\ defects[a] < Patience
  /\ defects' = [defects EXCEPT ![a] = defects[a] + 1]
  /\ givenUp' = [givenUp EXCEPT ![a] = TRUE]
  /\ standing' = [standing EXCEPT ![a] = "refused"]

(***************************************************************************)
(* A give-up with no entry behind it, which rule 5 permits and rule 4 does  *)
(* not require. Keeping it is what makes this a reading of the rules rather *)
(* than a truncation of them.                                               *)
(***************************************************************************)
GiveUp(a) ==
  /\ standing[a] = "inspecting"
  /\ ~givenUp[a]
  /\ givenUp' = [givenUp EXCEPT ![a] = TRUE]
  /\ standing' = [standing EXCEPT ![a] = "refused"]
  /\ UNCHANGED defects

Next ==
  \E a \in Applicants :
     \/ SendWord(a)
     \/ VisitFinds(a)
     \/ FailAndGiveUp(a)
     \/ GiveUp(a)

Spec == Init /\ [][Next]_vars

Observe == [standing |-> standing, defects |-> defects, givenUp |-> givenUp]

=============================================================================
