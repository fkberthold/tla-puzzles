-------------------------- MODULE ProbeDecomposed --------------------------
(***************************************************************************)
(* The same question as ProbeStoreFirst, asked of the copy-then-expunge      *)
(* server, where I expect the opposite answer.                              *)
(*                                                                          *)
(* MoveDecomposed can only set the \Deleted flag on a message that already   *)
(* has its target copy, because that is the order RFC 9051 section 6.4.8     *)
(* lists the steps in. So every flagged state in that model is also a        *)
(* both-mailboxes state, and clause 3 fails wherever clause 1 does.          *)
(*                                                                          *)
(* rc 0 here means clause 1 adds nothing over clauses 2 and 3 for the        *)
(* Thunderbird shape, and the third name only starts earning its place once  *)
(* the implementation flags before it copies. That is a claim about which    *)
(* server you are looking at, not about the RFC, and the pair of probes is   *)
(* the measurement.                                                          *)
(***************************************************************************)
EXTENDS MoveDecomposed

ClauseOneIsNoStronger ==
    (NotLostOrOrphaned /\ NotInBothMailboxes) => MovedOrUnaffected

===========================================================================
