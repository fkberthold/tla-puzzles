--------------------------- MODULE TxnRef ---------------------------
(***************************************************************************)
(* A STAND-IN reference for `txn-epoch-fence-vs-retry`, built for bead      *)
(* tla-8kgj. The problem is at step 5 and its reference is frozen at step   *)
(* 6, so this is not the shipped reference and must not be read as one. It  *)
(* carries the statement's frozen four-field Observe interface, its ten     *)
(* rules as written, and the instance its Checking section names, Leaves =  *)
(* 3. The system is the one in sources/spikes/txn-epoch-fence-vs-retry/.    *)
(*                                                                          *)
(* RULE 4 IS RENDERED AS AMENDED, which is the statement as it stands on    *)
(* main. Commit d1ba684 restored the fence the step 5 report called         *)
(* blocking: the desk now reads the gang's card against its own book and    *)
(* refuses a card that does not say the leaf it holds. Before that the      *)
(* raise read nothing, and the whole retry apparatus of rule 2, rule 6 and  *)
(* requirements 5 and 6 could be deleted with no verdict moving.            *)
(*                                                                          *)
(* ROW 4 OF RULE 5 IS THE MECHANISM. The desk recognises a second copy and  *)
(* writes the leaf it now holds onto the card, so the card and the book     *)
(* agree again. It is the only step that moves the card with no entry       *)
(* behind it, and the only route to a reading where the watch has logged a  *)
(* withdrawal and the card has caught up. The degenerate model deletes it.  *)
(*                                                                          *)
(* THE CEILING READING IS RULES 1 AND 6 WINNING, which the step 5 report    *)
(* records as one of two faithful readings. An entry needs a leaf to go on, *)
(* so every entry carries `leaf < Leaves` and a withdrawal at the last leaf *)
(* is disabled. That leaves the trap state the problem is about.            *)
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

(***************************************************************************)
(* Rule 7. A close the gang brought, entered on the last leaf, fills the    *)
(* book. A withdrawal never does, which is the asymmetry the whole problem  *)
(* turns on.                                                                *)
(***************************************************************************)
Fills == leaf + 1 = Leaves

(***************************************************************************)
(* Rule 4 as amended. The desk raises a permit from clear, completed or     *)
(* abandoned, and refuses a card that does not say the leaf it holds. It    *)
(* still does not count the leaves the book has left, which is the gap the  *)
(* problem runs through.                                                    *)
(***************************************************************************)
Raise ==
  /\ standing \in {"clear", "completed", "abandoned"}
  /\ card = leaf
  /\ standing' = "open"
  /\ UNCHANGED <<leaf, card, withdrawn>>

(***************************************************************************)
(* Rule 5 row 1, the sign-off. Rule 6 splits it in two: the card is written *)
(* if the gang waits for it, and nothing is written if the gang turns away.  *)
(***************************************************************************)
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

(***************************************************************************)
(* Rule 5 row 2, the surrender of an open permit, and row 3, the surrender  *)
(* of a gang that cannot tell whether its last permit reached the desk. The *)
(* desk takes row 3 at face value and enters it.                            *)
(***************************************************************************)
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

(***************************************************************************)
(* RULE 5 ROW 4, THE SECOND COPY. The desk has a surrender already entered  *)
(* against this gang and the card names the leaf that entry was written     *)
(* against, so it reads the card as a duplicate. It enters nothing and      *)
(* writes the leaf it now holds.                                            *)
(***************************************************************************)
SecondCopy ==
  /\ standing = "abandoned"
  /\ card = leaf - 1
  /\ card' = leaf
  /\ UNCHANGED <<standing, leaf, withdrawn>>

(***************************************************************************)
(* Rule 8. The fire watch reports a permit and the desk withdraws it. The   *)
(* gang is not at the desk, so nothing is written on its card, and rule 7   *)
(* keeps the book open however late the entry falls.                        *)
(***************************************************************************)
Withdraw ==
  /\ standing = "open"
  /\ leaf < Leaves
  /\ leaf' = leaf + 1
  /\ standing' = "abandoned"
  /\ withdrawn' = TRUE
  /\ UNCHANGED card

Next ==
  \/ Raise
  \/ SignOffCarded \/ SignOffTurnedAway
  \/ SurrenderCarded \/ SurrenderTurnedAway
  \/ SecondCopy
  \/ Withdraw

Spec == Init /\ [][Next]_vars

Observe == [standing |-> standing, leaf |-> leaf,
            card |-> card, withdrawn |-> withdrawn]

=============================================================================
