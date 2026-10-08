------------------------- MODULE AcmeRefObl -------------------------
(***************************************************************************)
(* The reference obligations for the `acme-challenge` degenerate-model      *)
(* package. Variable-free by construction.                                  *)
(*                                                                          *)
(* Three of the statement's nine requirements are stated here: 2, 7 and 8.  *)
(*                                                                          *)
(* REQUIREMENT 1 IS NOT, AND IT CANNOT BE. The faithful office writes an    *)
(* entry on a failed visit and leaves the man under inspection, so          *)
(* requirement 1 is false of the system the reference describes. A phi_i    *)
(* the reference itself refutes inverts every Adequacy run: the collapse    *)
(* would meet it and a faithful submission would miss it. So the obligation *)
(* is left out, and the fixture measures what happens when a SUBMISSION     *)
(* states it instead. See AcmeCollapseObl.                                  *)
(*                                                                          *)
(* Requirements 3, 4, 5, 6 and 9 are left out to keep the package cheap,    *)
(* not because anything is wrong with them.                                 *)
(***************************************************************************)
EXTENDS Naturals

ObsApplicants == {"a1", "a2"}
ObsPatience   == 2
ObsStandings  == {"issued", "inspecting", "allowed", "refused"}

ObsDomain == [standing: [ObsApplicants -> ObsStandings],
              defects:  [ObsApplicants -> 0 .. ObsPatience],
              givenUp:  [ObsApplicants -> BOOLEAN]]

(***************************************************************************)
(* PHI_1, requirement 2. Refusal waits for the give-up. Chaos reaches a man *)
(* refused with no give-up behind it, so this is the obligation that keeps  *)
(* the package standing.                                                    *)
(***************************************************************************)
Req_refusal_waits(o) ==
  \A a \in DOMAIN o.standing : o.standing[a] = "refused" => o.givenUp[a]

(***************************************************************************)
(* PHI_2, requirement 7, over a pair of successive observations.            *)
(***************************************************************************)
Step_settled_stays(o, p) ==
  \A a \in DOMAIN o.standing :
     o.standing[a] \in {"allowed", "refused"} => p.standing[a] = o.standing[a]

(***************************************************************************)
(* PHI_3, requirement 8. A give-up stands.                                  *)
(***************************************************************************)
Step_giveup_stands(o, p) ==
  \A a \in DOMAIN o.standing : o.givenUp[a] => p.givenUp[a]

(***************************************************************************)
(* THE TWO LANDMARKS. A Step_* obliges the package to two that no single    *)
(* observation satisfies together, and these two disagree about whether     *)
(* anybody has moved off `"issued"`.                                        *)
(*                                                                          *)
(* Landmark_retry IS THE LOOP TURNING, and it is what the statement's own   *)
(* tenth deliverable asks the learner to write: "a formula that's false the *)
(* moment the office goes back to a man it has already put an entry         *)
(* against", declared as an INVARIANT and run on its own. That deliverable  *)
(* landed in commit ae0ac0d after the step 5 report, and the landmark here  *)
(* is the same probe wired to a gate instead of to a learner's honesty.     *)
(***************************************************************************)
Landmark_retry(o) ==
  \E a \in DOMAIN o.standing :
     /\ o.standing[a] = "inspecting"
     /\ o.defects[a] >= 1

Landmark_opening(o) ==
  \A a \in DOMAIN o.standing : o.standing[a] = "issued"

=============================================================================
