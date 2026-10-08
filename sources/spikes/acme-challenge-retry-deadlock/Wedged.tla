------------------------------ MODULE Wedged ------------------------------
(***************************************************************************)
(* The same challenge object, with RFC 8555 section 8 taken as normative on *)
(* the state SHAPE rather than checked as an invariant.                     *)
(*                                                                         *)
(* Section 8.2 says a failed validation query MUST write an error.         *)
(* Section 8, as published, says a challenge object with an error MUST     *)
(* have status "invalid". Conjoin the two and the failed query itself       *)
(* carries the challenge to "invalid". Section 7.1.6 draws no arrow out of *)
(* "invalid".                                                              *)
(*                                                                         *)
(* THIS IS ALSO WHAT THE COLLAPSE PRODUCES. A reader who treats "a failed  *)
(* validation query" and "the server has given up" as one event writes     *)
(* exactly this module -- the diagram in section 7.1.6 invites that         *)
(* reading, since it labels the processing-to-invalid edge "Failed          *)
(* validation" and has no give-up edge at all. The two routes to this       *)
(* module are different motivations for the same text, which is why there   *)
(* is one module rather than two.                                          *)
(*                                                                         *)
(* It satisfies section 8. The price is the whole of section 8.2: no        *)
(* behaviour of this spec contains a second validation query. That is       *)
(* errata ID 5732's sentence, and Wedged.cfg is the measurement of it.      *)
(***************************************************************************)
EXTENDS Naturals

CONSTANTS Pending, Processing, Valid, Invalid, MaxQueries

Status == {Pending, Processing, Valid, Invalid}

VARIABLES
    status,
    errors,
    queries,
    gaveUp,
    clientRequest

vars == <<status, errors, queries, gaveUp, clientRequest>>

Obs == [status |-> status, errors |-> errors, queries |-> queries,
        gaveUp |-> gaveUp, clientRequest |-> clientRequest]

TypeOK ==
    /\ status \in Status
    /\ errors \in 0..MaxQueries
    /\ queries \in 0..MaxQueries
    /\ gaveUp \in BOOLEAN
    /\ clientRequest \in BOOLEAN

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
    /\ clientRequest' = FALSE
    /\ UNCHANGED <<errors, gaveUp>>

(* The one action that differs from Challenge.tla. Section 8.2's MUST-write
   and section 8's MUST-be-invalid, in a single step. There is no separate
   GiveUp, because section 8 leaves the server nowhere to stand between the
   failed query and "invalid". *)
FailedQueryForcesInvalid ==
    /\ status = Processing
    /\ queries < MaxQueries
    /\ queries' = queries + 1
    /\ errors' = errors + 1
    /\ status' = Invalid
    /\ gaveUp' = TRUE
    /\ clientRequest' = FALSE

ClientRequestsRetry ==
    /\ status = Processing
    /\ ~clientRequest
    /\ clientRequest' = TRUE
    /\ UNCHANGED <<status, errors, queries, gaveUp>>

Next ==
    \/ Respond
    \/ SuccessfulQuery
    \/ FailedQueryForcesInvalid
    \/ ClientRequestsRetry

Spec == Init /\ [][Next]_vars

ErrorImpliesInvalid == errors > 0 => status = Invalid

(* Erratum 5732: "it is never possible to retry any validation query
   (because 'invalid' is a final state for a challenge object)." Here the
   sentence is TRUE, so this invariant holds and TLC exits 0. *)
NeverTwoQueries == queries <= 1

(* Probes against the rc=0 above. A model that moved nowhere would also
   satisfy NeverTwoQueries, so each of these has to be refuted. *)
NeverProcessing == status # Processing
NeverInvalid    == status # Invalid
NoQueryEver     == queries = 0
NoErrorEver     == errors = 0
ClientNeverAsks == ~clientRequest
NeverValid      == status # Valid
=============================================================================
