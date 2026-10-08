------------------------- MODULE ProbeExpungeFirst -------------------------
(***************************************************************************)
(* The same two implications as ProbeStoreFirst, over the one server that    *)
(* reaches the empty location set.                                          *)
(*                                                                          *)
(* Between the two probe modules every shape loc[m] can take is reachable:   *)
(* {src} at the initial state, {src,tgt} after a copy, {tgt} after an        *)
(* expunge, and {} only here. An implication that holds over both has been   *)
(* checked against all four rather than against the three a tidier server    *)
(* happens to produce.                                                      *)
(***************************************************************************)
EXTENDS MoveExpungeFirst

ClauseOneImpliesNotBoth == MovedOrUnaffected => NotInBothMailboxes
ClauseOneImpliesNotLost == MovedOrUnaffected => NotLostOrOrphaned

\* Refuted means the empty location set really is reachable here, so the
\* implications above were checked against a state where clause 2 fails.
NothingEverVanishes == \A m \in Msg : loc[m] # {}

===========================================================================
