----------------------- MODULE AcmeFaithfulObl -----------------------
(***************************************************************************)
(* The control's own requirement: the statement's requirement 2, and not    *)
(* requirement 1.                                                           *)
(*                                                                          *)
(* THE OMISSION IS THE FINDING. A faithful office writes an entry on a      *)
(* failed visit and leaves the man under inspection, so requirement 1 is    *)
(* false of it. A faithful submission that states requirement 1 is graded   *)
(* over-constrained, correctly, because the requirement asks for more than  *)
(* the rules allow. There is no submission to this statement that both      *)
(* keeps the retry loop and states all nine.                                *)
(***************************************************************************)
EXTENDS Naturals

Req_refusal_after_giveup(o) ==
  \A a \in DOMAIN o.standing : o.standing[a] = "refused" => o.givenUp[a]

=============================================================================
