------------------------- MODULE TxnNoRetry -------------------------
(***************************************************************************)
(* THE DEGENERATE MODEL for `txn-epoch-fence-vs-retry`: the fire office     *)
(* with row 4 of rule 5 deleted outright. Everything else is the faithful   *)
(* office, byte for byte with TxnRef apart from the missing action and this *)
(* header.                                                                  *)
(*                                                                          *)
(* The step 5 reader measured it against rule 4 AS IT STOOD THEN, where the *)
(* raise read no card at all, and got the same vector of eight verdicts as  *)
(* the faithful office: 12 for requirement 1, 13 for requirement 2 and 0    *)
(* for the other six, over 16 distinct states at depth 5 against 22 at      *)
(* depth 6. So the deliverable the statement asked for could not tell this  *)
(* office from the real one. That is bead tla-n8oq's shape in this          *)
(* problem's idiom: the answer is unchanged over a model with no mechanism.  *)
(*                                                                          *)
(* COMMIT d1ba684 MOVED THAT, and this module is rendered against the       *)
(* statement as amended. The raise now refuses a card that disagrees with   *)
(* the book, and requirement 1 was replaced by the formula the step 5       *)
(* report recommended, which is false of the faithful office and true here. *)
(* So the statement's own verdict vector can see this model now, and the    *)
(* grader catches it twice over. Whether the problem still needs the        *)
(* grader for this is a question for step 6, and I would say it does: the   *)
(* second catch is the landmark, and nothing in the statement is one.        *)
(*                                                                          *)
(* The model is kept as the pre-amendment reading rather than retired,       *)
(* because the deletion it makes is still a reading the rules permit.        *)
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
  /\ card = leaf
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
