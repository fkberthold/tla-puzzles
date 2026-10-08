-------------------------- MODULE AcmeChallenge --------------------------
(***************************************************************************)
(* The seeded-bug matrix's reference spec (V2-PLAN.md 5.5).                 *)
(*                                                                         *)
(* This is Challenge.tla with the two switches resolved, because a variant  *)
(* set wants ONE spec to mutate rather than a family: erratum 5732's        *)
(* corrected section 8, and the clearing assumption that erratum has to     *)
(* carry to hold at all. Both are argued in Challenge.tla and measured in   *)
(* the report. A reference nobody's property holds on certifies nothing     *)
(* (PHASE 1, ORACLE_UNSOUND), so the reference has to be the version that   *)
(* works.                                                                   *)
(*                                                                         *)
(* The module name differs from Challenge deliberately. Variants are staged *)
(* under the reference's own module name, so a second module called         *)
(* Challenge in this tree would be one ambiguity nobody needs.              *)
(***************************************************************************)
EXTENDS Naturals

CONSTANTS Pending, Processing, Valid, Invalid, MaxQueries

Status == {Pending, Processing, Valid, Invalid}

VARIABLES status, errors, queries, gaveUp, clientRequest

vars == <<status, errors, queries, gaveUp, clientRequest>>

(* The normalising ALIAS operator the matrix's trace comparison runs through.
   Defined by the SPEC, never by a submission: the oracle run has to normalise
   identically or the comparison means nothing. *)
Obs == [status |-> status, errors |-> errors, queries |-> queries,
        gaveUp |-> gaveUp, clientRequest |-> clientRequest]

Init ==
    /\ status = Pending
    /\ errors = 0
    /\ queries = 0
    /\ gaveUp = FALSE
    /\ clientRequest = FALSE

Respond ==
    /\ status = Pending
    /\ status' = Processing
    /\ UNCHANGED <<errors, queries, gaveUp, clientRequest>>

SuccessfulQuery ==
    /\ status = Processing
    /\ queries < MaxQueries
    /\ queries' = queries + 1
    /\ status' = Valid
    /\ errors' = 0
    /\ clientRequest' = FALSE
    /\ UNCHANGED gaveUp

(* SEEDED BUG: the failed query writes no error entry. This is section 8.2's
   MUST dropped outright, and it is the variant that justifies the
   ProcessingAccountsForEveryQuery arm: section 8.2 constrains a TRANSITION,
   so no obvious state predicate catches it. *)
FailedQuery ==
    /\ status = Processing
    /\ queries < MaxQueries
    /\ queries' = queries + 1
    /\ status' = Processing
    /\ clientRequest' = FALSE
    /\ UNCHANGED <<errors, gaveUp>>

GiveUp ==
    /\ status = Processing
    /\ errors > 0
    /\ status' = Invalid
    /\ gaveUp' = TRUE
    /\ UNCHANGED <<errors, queries, clientRequest>>

ClientRequestsRetry ==
    /\ status = Processing
    /\ ~clientRequest
    /\ clientRequest' = TRUE
    /\ UNCHANGED <<status, errors, queries, gaveUp>>

Next ==
    \/ Respond
    \/ SuccessfulQuery
    \/ FailedQuery
    \/ GiveUp
    \/ ClientRequestsRetry

Spec == Init /\ [][Next]_vars
=============================================================================
