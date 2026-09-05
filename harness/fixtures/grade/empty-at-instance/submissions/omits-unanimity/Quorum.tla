---------------------------- MODULE Quorum ----------------------------
(***************************************************************************)
(* SUBMISSION: the rule is missing. This is the deficient spec a learner is *)
(* handed and asked to critique, and it issues a document as soon as ONE    *)
(* signer has approved.                                                     *)
(*                                                                          *)
(* It declares no CONSTANT and reads no roster of its own. It does not have  *)
(* to: the reference obligation is what carries the instance, so the same   *)
(* submission text grades at both instances and neither of them is written  *)
(* into this file.                                                          *)
(*                                                                          *)
(* Expected at `reference-three-signers/`: UNDER-constrained. It reaches an  *)
(* issued document that only "a" approved, and Req_unanimity is false there. *)
(*                                                                          *)
(* Expected at `reference/`, where the roster is empty: today it is a clean  *)
(* PASS at Adequacy 2 of 2. That is the bug. The obligation it is supposed   *)
(* to be missing asks for nothing at that instance, so meeting it says       *)
(* nothing about this spec, and a grade built on it says nothing either.     *)
(***************************************************************************)

VARIABLES issued, approvedBy

Names == {"a", "b", "c"}

Init == issued = FALSE /\ approvedBy = {}

Approve(s) == approvedBy' = approvedBy \cup {s} /\ UNCHANGED issued
Issue      == approvedBy # {} /\ issued' = TRUE /\ UNCHANGED approvedBy

Next == (\E s \in Names : Approve(s)) \/ Issue

Spec == Init /\ [][Next]_<<issued, approvedBy>>

(***************************************************************************)
(* The seal is derived here as it is in the reference, so Req_sealflag is   *)
(* the obligation this submission meets on its merits while the unanimity   *)
(* one is the one under test.                                               *)
(***************************************************************************)
Observe == [issued |-> issued, sealed |-> issued, approvedBy |-> approvedBy]

=============================================================================
