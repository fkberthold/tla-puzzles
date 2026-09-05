------------------------- MODULE QuorumRefObl -------------------------
(***************************************************************************)
(* The reference obligations for `empty-at-instance`, and the fixture       *)
(* itself. Bead tla-nyrb, clause C1.                                        *)
(*                                                                          *)
(* Req_unanimity is the rule the problem is about. It reads the CONSTANT    *)
(* `Signers`, so what it asks depends on the instance the package is graded *)
(* at, and constants.cfg beside this file picks that instance.              *)
(*                                                                          *)
(* AT THE COLLAPSED INSTANCE IT ASKS FOR NOTHING. `Signers = {}` makes the  *)
(* quantifier range empty, so Req_unanimity is true of every observation    *)
(* there is. No submission can fail it, a submission that omits the rule    *)
(* meets it, and grade.sh counts it toward a full Adequacy score anyway.    *)
(* That is the measured symptom: the problem is empty at that instance and  *)
(* nothing says so.                                                         *)
(*                                                                          *)
(* The sibling directory `reference-three-signers/` holds this same module  *)
(* text under a constants.cfg that names all three signers. Nothing else    *)
(* changes between the two, which is the whole point of the pair.           *)
(***************************************************************************)

CONSTANT Signers

(***************************************************************************)
(* The names the observation may carry. `Roster` rather than `Names`, and   *)
(* the difference matters. The Adequacy runs EXTEND the SUBMISSION's spec   *)
(* beside this module, so a name defined in both would be ambiguous there.  *)
(***************************************************************************)
Roster == {"a", "b", "c"}

ObsDomain == [issued: BOOLEAN, sealed: BOOLEAN, approvedBy: SUBSET Roster]

(***************************************************************************)
(* PHI_1. Nobody issues a document until every signer has approved it.      *)
(*                                                                          *)
(* Written as a quantifier over `Signers` rather than as `o.approvedBy =    *)
(* Signers` so that the submission never has to read the constant. The two  *)
(* forms say the same thing at the instance that matters, and only this one *)
(* leaves the submission alone. A submission spec that declared `Signers`   *)
(* would collide with the declaration above in every Adequacy run.          *)
(***************************************************************************)
Req_unanimity(o) == \A s \in Signers : o.issued => s \in o.approvedBy

(***************************************************************************)
(* PHI_2. The seal agrees with the document. One observation, two fields,   *)
(* and it is what refuses chaos: the domain lets the seal float free of the *)
(* document, so chaos reaches an unissued document that calls itself        *)
(* sealed.                                                                  *)
(*                                                                          *)
(* IT IS HERE TO KEEP THE PACKAGE STANDING. Without it the whole obligation *)
(* set is true of chaos at the collapsed instance, grade.sh refuses the      *)
(* package under the tla-x8s probe, and the fixture would go green for a    *)
(* reason that has nothing to do with this bead.                            *)
(***************************************************************************)
Req_sealflag(o) == o.sealed <=> o.issued

(***************************************************************************)
(* LANDMARK. An issued document is an observation the reference reaches, so *)
(* a submission has to reach it too.                                        *)
(***************************************************************************)
Landmark_issued(o) == o.issued

=============================================================================
