------------------------- MODULE TxnNoRetry -------------------------
(***************************************************************************)
(* THE DEGENERATE MODEL for `txn-epoch-fence-vs-retry`: the fire office     *)
(* with row 4 of rule 5 deleted outright. Everything else is the faithful   *)
(* office, byte for byte with TxnRef apart from the missing action and this *)
(* header.                                                                  *)
(*                                                                          *)
(* The step 5 reader measured the consequence directly. Every one of the    *)
(* statement's eight requirements comes back with the same verdict it gives *)
(* against the faithful office, 12 for requirement 1, 13 for requirement 2  *)
(* and 0 for the other six, over 16 distinct states at depth 5 against 22   *)
(* at depth 6. So the deliverable the statement asks for, a vector of eight *)
(* verdicts, cannot tell this office from the real one.                      *)
(*                                                                          *)
(* That is bead tla-n8oq's shape in this problem's idiom. The answer is      *)
(* unchanged over a model with no mechanism, and the whole retry apparatus  *)
(* of rule 2, rule 6 and requirements 5 and 6 carries no weight.            *)
(***************************************************************************)
EXTENDS Naturals

Leaves == 3

VARIABLES standing, leaf, card, withdrawn

vars == <<standing, leaf, card, withdrawn>>

Init ==
  /\ standing  = "clear"
  /\ leaf      = 1
  /\ card      = 1
  /\ withdrawn = FALSE

Fills == leaf + 1 = Leaves

Raise ==
  /\ standing \in {"clear", "completed", "abandoned"}
  /\ standing' = "open"
  /\ UNCHANGED <<leaf, card, withdrawn>>

SignOffCarded ==
  /\ standing = "open"
  /\ card = leaf
  /\ leaf < Leaves
  /\ leaf' = leaf + 1
  /\ card' = leaf + 1
  /\ standing' = IF Fills THEN "spent" ELSE "completed"
  /\ UNCHANGED withdrawn

SignOffTurnedAway ==
  /\ standing = "open"
  /\ card = leaf
  /\ leaf < Leaves
  /\ leaf' = leaf + 1
  /\ standing' = IF Fills THEN "spent" ELSE "completed"
  /\ UNCHANGED <<card, withdrawn>>

SurrenderCarded ==
  /\ standing \in {"open", "clear", "completed", "abandoned"}
  /\ card = leaf
  /\ leaf < Leaves
  /\ leaf' = leaf + 1
  /\ card' = leaf + 1
  /\ standing' = IF Fills THEN "spent" ELSE "abandoned"
  /\ UNCHANGED withdrawn

SurrenderTurnedAway ==
  /\ standing \in {"open", "clear", "completed", "abandoned"}
  /\ card = leaf
  /\ leaf < Leaves
  /\ leaf' = leaf + 1
  /\ standing' = IF Fills THEN "spent" ELSE "abandoned"
  /\ UNCHANGED <<card, withdrawn>>

Withdraw ==
  /\ standing = "open"
  /\ leaf < Leaves
  /\ leaf' = leaf + 1
  /\ standing' = "abandoned"
  /\ withdrawn' = TRUE
  /\ UNCHANGED card

(***************************************************************************)
(* The next-state relation with no second-copy row in it. A card left one   *)
(* leaf behind the book by a withdrawal stays there, because every          *)
(* remaining action that touches the card needs the card to agree with the  *)
(* book first.                                                              *)
(***************************************************************************)
Next ==
  \/ Raise
  \/ SignOffCarded \/ SignOffTurnedAway
  \/ SurrenderCarded \/ SurrenderTurnedAway
  \/ Withdraw

Spec == Init /\ [][Next]_vars

Observe == [standing |-> standing, leaf |-> leaf,
            card |-> card, withdrawn |-> withdrawn]

=============================================================================
