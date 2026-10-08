------------------------------ MODULE Oracle ------------------------------
(***************************************************************************)
(* The author's property, which is the matrix's instrument rather than its  *)
(* subject. PHASE 1 checks it against the reference and PHASE 3 against     *)
(* every variant, both before any submission is graded, so that an inert    *)
(* mutant is billed to the variant set and never to a learner.              *)
(*                                                                         *)
(* Each arm names the sentence it comes from. Six of the seven are RFC      *)
(* text. The seventh is flagged where it sits.                              *)
(***************************************************************************)
EXTENDS AcmeChallenge

TypeOK ==
    /\ status \in Status
    /\ errors \in 0..MaxQueries
    /\ queries \in 0..MaxQueries
    /\ gaveUp \in BOOLEAN
    /\ clientRequest \in BOOLEAN

(* Section 8, as errata ID 5732 corrects it. *)
ErrorImpliesProcessingOrInvalid ==
    errors > 0 => status \in {Processing, Invalid}

(* Section 8.2: "The server MUST add an entry to the 'error' field in the
   challenge after each failed validation query." One entry per failed query
   means entries cannot outnumber the queries. *)
ErrorsBoundedByQueries == errors <= queries

(* Section 7.1.6: "Challenge objects are created in the 'pending' state."
   Nothing has been attempted while the object is still in it, and section
   7.1.6 draws no arrow back into pending. *)
PendingIsUntouched == status = Pending => (queries = 0 /\ errors = 0)

(* Section 8.2: "it is only marked 'invalid' once the server has given up",
   with section 7.1.6's diagram drawing no arrow out of invalid. *)
GiveUpIsFinal == gaveUp => status = Invalid

(* Section 8: "If the server sets a challenge's 'status' to 'invalid', it
   SHOULD also include the 'error' field to help the client diagnose why the
   challenge failed." A SHOULD, not a MUST -- the weakest arm here, and
   labelled so rather than quietly promoted. *)
InvalidCarriesError == status = Invalid => errors > 0

(* The state-level shadow of section 8.2's MUST. Section 8.2 constrains a
   TRANSITION, and a transition is not a state predicate, so the arm that
   catches a dropped error write has to be derived: while the challenge is
   still processing, every query so far has failed, and each one wrote an
   entry. A successful query is the only query that writes none, and it
   leaves "processing". So in "processing" the two counters agree.

   This arm depends on the reference's action structure in a way the other
   six do not. It is the arm the seeded-bug matrix exists to validate. *)
ProcessingAccountsForEveryQuery ==
    status = Processing => errors = queries

Inv ==
    /\ TypeOK
    /\ ErrorImpliesProcessingOrInvalid
    /\ ErrorsBoundedByQueries
    /\ PendingIsUntouched
    /\ GiveUpIsFinal
    /\ InvalidCarriesError
    /\ ProcessingAccountsForEveryQuery
=============================================================================
