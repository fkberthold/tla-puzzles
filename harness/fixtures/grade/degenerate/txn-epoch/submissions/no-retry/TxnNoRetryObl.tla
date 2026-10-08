----------------------- MODULE TxnNoRetryObl -----------------------
(***************************************************************************)
(* The degenerate model's own requirement. One, and that is faithful to the *)
(* statement rather than thin: the task is to classify eight claims, and a  *)
(* learner states as a requirement only the ones they report true.          *)
(*                                                                          *)
(* Requirement 5 is true of the faithful office as well, so obligation 2    *)
(* has nothing to refute and the Relational suite rests on the landmarks    *)
(* alone. That is the point of the fixture.                                 *)
(***************************************************************************)
EXTENDS Naturals

Req_card_never_runs_ahead(o) == o.card =< o.leaf

=============================================================================
