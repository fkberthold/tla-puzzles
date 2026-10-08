----------------------------- MODULE Diagram -----------------------------
(***************************************************************************)
(* The challenge state diagram published in RFC 8555 section 7.1.6,         *)
(* transcribed as a next-state relation over "status" alone.                *)
(*                                                                         *)
(*            pending                                                      *)
(*               |                                                         *)
(*               | Receive                                                 *)
(*               | response                                                *)
(*               V                                                         *)
(*           processing <-+                                                *)
(*               |   |    | Server retry or                                *)
(*               |   |    | client retry request                           *)
(*               |   +----+                                                *)
(*               |                                                         *)
(*               |                                                         *)
(*   Successful  |   Failed                                                *)
(*   validation  |   validation                                            *)
(*     +---------+---------+                                               *)
(*     |                   |                                               *)
(*     V                   V                                               *)
(*   valid              invalid                                            *)
(*                                                                         *)
(*                  State Transitions for Challenge Objects                *)
(*                                                                         *)
(* This is a SECOND, INDEPENDENT description of the same machine. It is    *)
(* transcribed from the picture and from nothing else: four edges, four    *)
(* labels, and no counter. Errata ID 7826 settles an ambiguity in the      *)
(* section 8.2 prose by appeal to this diagram, so the community treats it *)
(* as the arbiter, which is the reason it is worth checking the prose      *)
(* against.                                                                *)
(*                                                                         *)
(* WHAT THE DIAGRAM CANNOT SAY. It carries no counter, so "a second        *)
(* validation query happened" is not a predicate over its state. The       *)
(* retry loop is a status SELF-LOOP, and a status-only machine cannot      *)
(* distinguish one trip round it from ten. Erratum 5732's claim --         *)
(* "it is never possible to retry any validation query" -- is therefore    *)
(* not expressible in this module. It needs the prose model's counter.      *)
(***************************************************************************)

CONSTANTS Pending, Processing, Valid, Invalid

DStatus == {Pending, Processing, Valid, Invalid}

VARIABLE status

(* "Challenge objects are created in the 'pending' state." *)
DInit == status = Pending

(* The edge labelled "Receive response". *)
ReceiveResponse == status = Pending /\ status' = Processing

(* The self-loop, labelled "Server retry or client retry request". *)
RetryLoop == status = Processing /\ status' = Processing

(* The edge labelled "Successful validation". *)
SuccessfulValidation == status = Processing /\ status' = Valid

(* The edge labelled "Failed validation". *)
FailedValidation == status = Processing /\ status' = Invalid

DNext ==
    \/ ReceiveResponse
    \/ RetryLoop
    \/ SuccessfulValidation
    \/ FailedValidation

DSpec == DInit /\ [][DNext]_status

(* The diagram draws no arrow out of either bottom box.
   The parentheses round the antecedent are load-bearing. Without them SANY
   commits to a function-constructor reading at the opening bracket and
   reports a parse error at the `]_`, 47 columns away. ParseBad.tla and
   ParseGood.tla are the isolated pair. *)
TerminalIsTerminal ==
    [][(status \in {Valid, Invalid}) => status' = status]_status
=============================================================================
