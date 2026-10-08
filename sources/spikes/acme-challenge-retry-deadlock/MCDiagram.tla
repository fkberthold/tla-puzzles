----------------------------- MODULE MCDiagram -----------------------------
(***************************************************************************)
(* The prose model checked against the published diagram.                   *)
(*                                                                         *)
(* Two separate questions, and the answers differ, which is the finding:    *)
(*                                                                         *)
(*   THE GRAPH. Does every transition of the section 8.2 prose model        *)
(*   project onto an edge of the section 7.1.6 diagram? Refines below,      *)
(*   checked as a PROPERTY. The attested shape from                        *)
(*   .claude/rules/tla-practice.md section 5.                               *)
(*                                                                         *)
(*   THE LABELS. Does the event the diagram calls "Failed validation" mean  *)
(*   the same thing section 8.2 calls a failed validation query? The four   *)
(*   implied actions below answer that, one label at a time.                *)
(***************************************************************************)
EXTENDS Challenge

D == INSTANCE Diagram

(* Does the prose model's status projection stay inside the diagram? *)
Refines == D!DSpec

(* The diagram's edge labelled "Failed validation" runs processing to
   invalid. Section 8.2's failed validation query leaves the status at
   "processing". So these two readings of one phrase are not the same edge. *)
FailedQueryIsFailedValidation == [][FailedQuery => D!FailedValidation]_vars

(* Section 8.2 never calls the give-up decision a failed validation, and the
   diagram has no give-up edge. This is the pairing that reconciles them. *)
GiveUpIsFailedValidation == [][GiveUp => D!FailedValidation]_vars

(* The diagram labels its self-loop "Server retry or client retry request".
   Both of the prose model's status-preserving actions land there. *)
FailedQueryIsRetryLoop   == [][FailedQuery => D!RetryLoop]_vars
ClientRetryIsRetryLoop   == [][ClientRequestsRetry => D!RetryLoop]_vars
=============================================================================
