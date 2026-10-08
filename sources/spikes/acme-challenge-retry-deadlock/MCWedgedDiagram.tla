-------------------------- MODULE MCWedgedDiagram --------------------------
(***************************************************************************)
(* The wedged model against the same published diagram.                     *)
(*                                                                         *)
(* This is the uncomfortable half of the prose-against-diagram result. The  *)
(* wedged model refines the diagram, AND its failed-query action sits on    *)
(* the edge the diagram labels "Failed validation" -- which the prose       *)
(* model's failed query does not. So on the labels, it is the WEDGED model  *)
(* that matches the picture, and errata ID 7826 is on record treating the   *)
(* picture as the arbiter.                                                  *)
(***************************************************************************)
EXTENDS Wedged

D == INSTANCE Diagram

Refines == D!DSpec

FailedQueryIsFailedValidation ==
    [][FailedQueryForcesInvalid => D!FailedValidation]_vars

ClientRetryIsRetryLoop == [][ClientRequestsRetry => D!RetryLoop]_vars
=============================================================================
