--------------------------- MODULE TxnFaithful ---------------------------
(***************************************************************************)
(* THE CONTROL for `txn-epoch`, and the reason the `no-retry` result is     *)
(* evidence of anything. It is TxnRef's text under another module name, so  *)
(* it reaches the landmark and must grade PASS. A landmark nothing reaches  *)
(* refuses every submission alike.                                          *)
(*                                                                          *)
(* RULE 4 IS RENDERED AS THE STATEMENT WRITES IT: the desk does not read    *)
(* the gang's card when it raises a permit. The step 5 report calls that    *)
(* clause blocking and recommends changing it, and the recommendation is    *)
(* not taken here. This package grades a degenerate model against the       *)
(* statement as shipped, so changing the clause would be measuring a        *)
(* different artifact.                                                      *)
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
(* Rule 4. The desk raises a permit from clear, completed or abandoned, and *)
(* reads neither the card nor the leaves the book has left.                 *)
(***************************************************************************)
Raise ==
  /\ standing \in {"clear", "completed", "abandoned"}
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
