--------------------------- MODULE WeakFloorOnly ---------------------------
(***************************************************************************)
(* THE PROPERTY A READER WRITES IF CLAUSE 1 LOOKS REDUNDANT.                *)
(*                                                                          *)
(* Clause 1 implies clauses 2 and 3 as arithmetic over the location set, so  *)
(* dropping it looks free: "moved or unaffected" seems to be no more than    *)
(* "in at least one mailbox" and "in no more than one". This module is that  *)
(* reading, and it is the submission that measures what the third name buys. *)
(*                                                                          *)
(* It should miss exactly one variant, `stray-deleted-flag`, where the       *)
(* message sits in one mailbox carrying a \Deleted flag. Both clauses here   *)
(* hold in that state.                                                      *)
(*                                                                          *)
(* Expected verdict: PROPERTY_TOO_WEAK at rc 40, naming stray-deleted-flag   *)
(* and nothing else.                                                         *)
(***************************************************************************)
EXTENDS MoveAtomic

Inv == /\ TypeOK
       /\ NotLostOrOrphaned
       /\ NotInBothMailboxes

===========================================================================
