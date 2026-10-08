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

FailedQuery ==
    /\ status = Processing
    /\ queries < MaxQueries
    /\ queries' = queries + 1
    /\ errors' = errors + 1
    /\ status' = Processing
    /\ clientRequest' = FALSE
    /\ UNCHANGED gaveUp

(* SEEDED BUG: the server gives up before any query has failed, so the
   challenge reaches "invalid" with an empty error field. The shape of a
   give-up driven by a wall-clock deadline rather than by a failure count. *)
GiveUp ==
    /\ status = Processing
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
