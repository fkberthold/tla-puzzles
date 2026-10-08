--------------------------- MODULE AcmeRef ---------------------------
(***************************************************************************)
(* A STAND-IN reference for `acme-challenge-retry-deadlock`, built for bead *)
(* tla-8kgj. The problem is at step 5 and its reference is frozen at step   *)
(* 6, so this is not the shipped reference. It carries the statement's      *)
(* frozen three-field Observe interface, the instance its Checking section  *)
(* names, and the system of                                                 *)
(* sources/spikes/acme-challenge-retry-deadlock/matrix/reference/.           *)
(*                                                                          *)
(* THE FAITHFUL READING OF THE RULES, which is the one where the give-up is *)
(* its own act. Rule 4 has the office write an entry after each failed      *)
(* visit, and rule 5 says that while the office is still going back the man *)
(* stands under inspection. So a failed visit raises his defect count and   *)
(* leaves him at `"inspecting"`, and only a give-up refuses him.             *)
(*                                                                          *)
(* THIS READING REFUTES REQUIREMENT 1 OF THE STATEMENT, and that is a fact  *)
(* about the statement rather than a defect here. Requirement 1 says an     *)
(* entry on the list means refused, and the step 5 reader measured the      *)
(* faithful reading at rc 12 against it at depth 3. The contradiction is    *)
(* the candidate's content and the statement preserves it on purpose, so    *)
(* requirement 1 is not stated as a reference obligation. See AcmeRefObl.    *)
(***************************************************************************)
EXTENDS Naturals

Applicants == {"a1", "a2"}
Patience   == 2

VARIABLES standing, defects, givenUp

vars == <<standing, defects, givenUp>>

(***************************************************************************)
(* Rule 8. Every applicant stands with his plate issued and no word back,   *)
(* no defect list carries an entry, and the office has given up on nobody.  *)
(***************************************************************************)
Init ==
  /\ standing = [a \in Applicants |-> "issued"]
  /\ defects  = [a \in Applicants |-> 0]
  /\ givenUp  = [a \in Applicants |-> FALSE]

(***************************************************************************)
(* Rule 2. The first word moves him off `"issued"` and the office starts    *)
(* going out to look. Later word changes nothing, so it is a stutter on the *)
(* observation and is not an action here.                                   *)
(***************************************************************************)
SendWord(a) ==
  /\ standing[a] = "issued"
  /\ standing' = [standing EXCEPT ![a] = "inspecting"]
  /\ UNCHANGED <<defects, givenUp>>

(***************************************************************************)
(* Rule 3. A visit that finds the plate moves him to allowed.               *)
(***************************************************************************)
VisitFinds(a) ==
  /\ standing[a] = "inspecting"
  /\ ~givenUp[a]
  /\ standing' = [standing EXCEPT ![a] = "allowed"]
  /\ UNCHANGED <<defects, givenUp>>

(***************************************************************************)
(* RULES 4 AND 5 TOGETHER, AND THE STEP THE DEGENERATE MODEL COLLAPSES. The *)
(* office writes an entry after a failed visit and the man stays under      *)
(* inspection, because nothing has given up on him yet. Rule 3 caps the     *)
(* fruitless visits at Patience.                                            *)
(***************************************************************************)
VisitFails(a) ==
  /\ standing[a] = "inspecting"
  /\ ~givenUp[a]
  /\ defects[a] < Patience
  /\ defects' = [defects EXCEPT ![a] = defects[a] + 1]
  /\ UNCHANGED <<standing, givenUp>>

(***************************************************************************)
(* Rule 5. The office gives up when it chooses, nothing forces it, and the  *)
(* give-up is what marks him refused.                                      *)
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
     \/ VisitFails(a)
     \/ GiveUp(a)

Spec == Init /\ [][Next]_vars

Observe == [standing |-> standing, defects |-> defects, givenUp |-> givenUp]

=============================================================================
