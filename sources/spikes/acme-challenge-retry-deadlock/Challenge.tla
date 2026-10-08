---------------------------- MODULE Challenge ----------------------------
(***************************************************************************)
(* RFC 8555 challenge validation, modelled as the APPLICATION rather than  *)
(* the mechanism.                                                          *)
(*                                                                         *)
(* One challenge object, two counters. No HTTP, no DNS, no JWS, no nonce,  *)
(* no Retry-After header, no authorization object and no order object.     *)
(* None of those can change the answer: the question is whether a second   *)
(* validation query is reachable at all, and that is a fact about the       *)
(* status field and the error field.                                       *)
(*                                                                         *)
(* THE THREE NORMATIVE SENTENCES THIS MODULE HOLDS AT ONCE                 *)
(*                                                                         *)
(* S1, section 8.2: "While the server is still trying, the status of the   *)
(*     challenge remains 'processing'; it is only marked 'invalid' once     *)
(*     the server has given up."                                           *)
(*                                                                         *)
(* S2, section 8.2: "The server MUST add an entry to the 'error' field in  *)
(*     the challenge after each failed validation query."                  *)
(*                                                                         *)
(* S3, section 8: "A challenge object with an error MUST have status       *)
(*     equal to 'invalid'."                                                *)
(*                                                                         *)
(* S1 and S2 are built into the next-state relation. S3 is stated below as *)
(* the invariant ErrorImpliesInvalid, and Challenge.cfg checks it. The     *)
(* three cannot all hold, so that check fails.                             *)
(*                                                                         *)
(* THE MODELLING DECISION THE RFC LEAVES TO THE READER                     *)
(*                                                                         *)
(* S1 names two separate events: a failed query, after which the status    *)
(* remains "processing", and the server giving up, after which it is        *)
(* "invalid". FailedQuery and GiveUp below are therefore two actions, and  *)
(* writing an error is something only the first of them does.               *)
(*                                                                         *)
(* Collapse them into one action and the contradiction disappears. See     *)
(* Wedged.tla, which is that collapse, and which satisfies S3 at the price *)
(* the erratum names.                                                       *)
(***************************************************************************)
EXTENDS Naturals

CONSTANTS
    Pending,        \* status values. MODEL VALUES, never strings: a string
    Processing,     \* beside an integer counter is a cross-type comparison
    Valid,          \* and TLC aborts at rc=255 rather than failing a check.
    Invalid,
    MaxQueries,     \* validation queries the authority is willing to make
    ClearOnSuccess  \* see the note below. TRUE is NOT in the RFC.

Status == {Pending, Processing, Valid, Invalid}

VARIABLES
    status,         \* the challenge object's "status" field, section 8
    errors,         \* how many entries its "error" field carries, section 8
    queries,        \* validation queries made so far, section 8.2
    gaveUp,         \* the authority has decided the attempt is dead, section 8.2
    clientRequest   \* the client has an outstanding retry request, section 8.2

vars == <<status, errors, queries, gaveUp, clientRequest>>

(* A record built from the variables, for ALIAS only. It is a display
   mechanism and asserts nothing; see .claude/rules/tla-practice.md section 5. *)
Obs == [status |-> status, errors |-> errors, queries |-> queries,
        gaveUp |-> gaveUp, clientRequest |-> clientRequest]

ASSUME ClearOnSuccess \in BOOLEAN

TypeOK ==
    /\ status \in Status
    /\ errors \in 0..MaxQueries
    /\ queries \in 0..MaxQueries
    /\ gaveUp \in BOOLEAN
    /\ clientRequest \in BOOLEAN

(* Section 7.1.6: "Challenge objects are created in the 'pending' state." *)
Init ==
    /\ status = Pending
    /\ errors = 0
    /\ queries = 0
    /\ gaveUp = FALSE
    /\ clientRequest = FALSE

(* Section 7.1.6: "They transition to the 'processing' state when the client
   responds to the challenge (see Section 7.5.1) and the server begins
   attempting to validate that the client has completed the challenge." *)
Respond ==
    /\ status = Pending
    /\ status' = Processing
    /\ UNCHANGED <<errors, queries, gaveUp, clientRequest>>

(* Section 7.1.6: "If validation is successful, the challenge moves to the
   'valid' state".

   ClearOnSuccess IS AN ASSUMPTION THE RFC DOES NOT STATE, and the reason it
   is a switch rather than a decision is that the choice changes the verdict.

   FALSE is the faithful reading: nothing in RFC 8555 says the error field is
   emptied, so entries written under section 8.2 survive into "valid". Under
   that reading even erratum 5732's corrected sentence fails -- see
   MCErratum, which exits 12 on a 4-state trace.

   TRUE is the reading errata ID 7826 implies when it calls the error field
   the server's "retry state", which stops being meaningful once the
   challenge leaves "processing". That erratum is still status Reported, so
   this is the community's unratified reading and not the standard. *)
SuccessfulQuery ==
    /\ status = Processing
    /\ queries < MaxQueries
    /\ queries' = queries + 1
    /\ status' = Valid
    /\ clientRequest' = FALSE
    /\ errors' = IF ClearOnSuccess THEN 0 ELSE errors
    /\ UNCHANGED gaveUp

(* S2 is the errors' conjunct and S1's first half is the status' conjunct.
   Both are quoted in the module header. The clientRequest' conjunct is
   section 8.2's "Servers SHOULD retry a request immediately on receiving
   such a POST request": the outstanding request, if there was one, is now
   served. *)
FailedQuery ==
    /\ status = Processing
    /\ queries < MaxQueries
    /\ queries' = queries + 1
    /\ errors' = errors + 1
    /\ status' = Processing
    /\ clientRequest' = FALSE
    /\ UNCHANGED gaveUp

(* S1's second half: "it is only marked 'invalid' once the server has given
   up." This action is the give-up decision, and it is deliberately NOT the
   action that writes an error. The guard is section 8.2's own premise that
   the server has been trying: you cannot give up on retrying before a query
   has failed. *)
GiveUp ==
    /\ status = Processing
    /\ errors > 0
    /\ status' = Invalid
    /\ gaveUp' = TRUE
    /\ UNCHANGED <<errors, queries, clientRequest>>

(* Section 8.2: "Clients can explicitly request a retry by re-sending their
   response to a challenge in a new POST request (with a new nonce, etc.)."
   Section 7.1.6: "client requests for retries do not cause a state change",
   which is the UNCHANGED status conjunct. *)
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

(***************************************************************************)
(* THE TWO READINGS OF SECTION 8                                           *)
(***************************************************************************)

(* S3 as RFC 8555 section 8 publishes it: "A challenge object with an error
   MUST have status equal to 'invalid'." *)
ErrorImpliesInvalid == errors > 0 => status = Invalid

(* S3 as errata ID 5732 corrects it, status Verified: "A challenge object
   with an error MUST have status equal to 'processing' or 'invalid'." *)
ErrorImpliesProcessingOrInvalid ==
    errors > 0 => status \in {Processing, Invalid}

(***************************************************************************)
(* PROBES. Each one asserts something the model should refute. A clean run  *)
(* that is clean because nothing moved is worthless, so every rc=0 claim in *)
(* the report is paired with a probe below that reaches rc=12.              *)
(***************************************************************************)

NeverProcessing  == status # Processing
NeverValid       == status # Valid
NeverInvalid     == status # Invalid
NeverGaveUp      == ~gaveUp
ClientNeverAsks  == ~clientRequest
NoErrorEver      == errors = 0
ErrorsNeverTwo   == errors <= 1
NoQueryEver      == queries = 0

(* The erratum's own sentence, negated. "it is never possible to retry any
   validation query". A model in which the retry mechanism works refutes
   this; a model wedged by S3 satisfies it. *)
NeverTwoQueries  == queries <= 1

(* Not a probe. The claim that gaveUp is a FUNCTION of status in this model,
   which is why it can be carried for nothing: it adds no reachable state.
   Checked rather than asserted, because "it costs nothing" is exactly the
   kind of claim that is true until an action is added that breaks it. *)
GaveUpIffInvalid == gaveUp <=> (status = Invalid)
=============================================================================
