----------------------- MODULE TxnNoRetryObl -----------------------
(***************************************************************************)
(* The degenerate model's own requirements. Two, and that is faithful to    *)
(* the statement rather than thin: the task is to classify eight claims,    *)
(* and a learner states as a requirement only the ones they report true.    *)
(*                                                                          *)
(* Requirement 5 is true of the faithful office as well, so obligation 2    *)
(* has nothing to refute there.                                            *)
(*                                                                          *)
(* REQUIREMENT 1 IS THE OTHER ONE, AND IT IS WHAT COMMIT d1ba684 PUT        *)
(* THERE. A card on the last leaf means a book taken back. It is true of    *)
(* this office, because the only route to a card on the last leaf is a      *)
(* close the gang brought, and rule 7 makes that close fill the book. It is *)
(* FALSE of the faithful office, where row 4 of rule 5 writes the last leaf *)
(* onto a card with the standing still at `"abandoned"`.                     *)
(*                                                                          *)
(* So this package is caught twice, the same shape as `acme-challenge`:     *)
(* obligation 2 refutes a stated requirement, and the landmark is           *)
(* unreachable as well.                                                     *)
(***************************************************************************)
EXTENDS Naturals

LastLeaf == 3

Req_card_never_runs_ahead(o) == o.card =< o.leaf

Req_card_on_last_leaf_means_spent(o) ==
  o.card = LastLeaf => o.standing = "spent"

=============================================================================
