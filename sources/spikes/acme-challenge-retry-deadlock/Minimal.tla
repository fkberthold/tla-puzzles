------------------------------ MODULE Minimal ------------------------------
(***************************************************************************)
(* The same anomaly with gaveUp and clientRequest deleted. Three variables. *)
(*                                                                         *)
(* Built to price the other two, the way the fencing spike priced its       *)
(* clock. What each one buys:                                              *)
(*                                                                         *)
(*   gaveUp        makes the give-up decision visible IN THE STATE rather   *)
(*                 than only in the action structure, which is what lets    *)
(*                 the finality of a give-up be a state invariant instead   *)
(*                 of a temporal one. It is a function of status in every   *)
(*                 model here, so it should cost nothing; the report has    *)
(*                 the measurement.                                        *)
(*                                                                         *)
(*   clientRequest is the only reason the model has an action that section  *)
(*                 7.1.6's "client requests for retries do not cause a      *)
(*                 state change" can be checked against. Delete it and      *)
(*                 the client-initiated retry of section 8.2 stops being a  *)
(*                 distinguishable event.                                  *)
(*                                                                         *)
(* Neither is load-bearing for the contradiction. This module reaches it.   *)
(***************************************************************************)
EXTENDS Naturals

CONSTANTS Pending, Processing, Valid, Invalid, MaxQueries, ClearOnSuccess

Status == {Pending, Processing, Valid, Invalid}

VARIABLES status, errors, queries

vars == <<status, errors, queries>>

TypeOK ==
    /\ status \in Status
    /\ errors \in 0..MaxQueries
    /\ queries \in 0..MaxQueries

Init ==
    /\ status = Pending
    /\ errors = 0
    /\ queries = 0

Respond ==
    /\ status = Pending
    /\ status' = Processing
    /\ UNCHANGED <<errors, queries>>

(* See the ClearOnSuccess note in Challenge.tla. TRUE is not in the RFC. *)
SuccessfulQuery ==
    /\ status = Processing
    /\ queries < MaxQueries
    /\ queries' = queries + 1
    /\ status' = Valid
    /\ errors' = IF ClearOnSuccess THEN 0 ELSE errors

FailedQuery ==
    /\ status = Processing
    /\ queries < MaxQueries
    /\ queries' = queries + 1
    /\ errors' = errors + 1
    /\ status' = Processing

GiveUp ==
    /\ status = Processing
    /\ errors > 0
    /\ status' = Invalid
    /\ UNCHANGED <<errors, queries>>

Next == Respond \/ SuccessfulQuery \/ FailedQuery \/ GiveUp

Spec == Init /\ [][Next]_vars

ErrorImpliesInvalid == errors > 0 => status = Invalid
ErrorImpliesProcessingOrInvalid ==
    errors > 0 => status \in {Processing, Invalid}
NeverTwoQueries == queries <= 1
=============================================================================
