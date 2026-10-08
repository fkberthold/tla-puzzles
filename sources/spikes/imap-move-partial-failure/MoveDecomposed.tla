-------------------------- MODULE MoveDecomposed --------------------------
(***************************************************************************)
(* THE SERVER THAT RUNS THE RFC'S OWN DECOMPOSITION AND LETS YOU SEE IT.    *)
(*                                                                          *)
(* RFC 9051 section 6.4.8 gives MOVE a three-step equivalent:                *)
(*                                                                          *)
(*     1.  [UID] COPY                                                       *)
(*     2.  [UID] STORE +FLAGS.SILENT \DELETED                               *)
(*     3.  UID EXPUNGE                                                      *)
(*                                                                          *)
(* and then takes one thing back: "the intermediate states produced by      *)
(* those steps do not occur".  This module is the same three steps with     *)
(* that sentence deleted, so the intermediate states DO occur.  Everything  *)
(* else is MoveAtomic.                                                      *)
(*                                                                          *)
(* That is Thunderbird bug 610131: bulk move implemented as copy then       *)
(* delete, interrupted, leaving messages in both folders.  It is also the   *)
(* second description the RFC hands you of the same machine, which makes it *)
(* the natural thing to check the model against.                            *)
(***************************************************************************)
EXTENDS MoveBase

(***************************************************************************)
(* Step 1. The target copy lands while the source copy is still there, so   *)
(* the message is now in both mailboxes.                                    *)
(***************************************************************************)
CopyOne(m) ==
    /\ resp = "open"
    /\ m \in pending
    /\ Target \notin loc[m]
    /\ loc' = [loc EXCEPT ![m] = loc[m] \cup {Target}]
    /\ UNCHANGED << flagged, pending, resp >>

(***************************************************************************)
(* Step 2. The source copy is marked \Deleted.  It is still in exactly one  *)
(* mailbox and it is no longer as it was, which is the state that separates *)
(* clause 1 from clauses 2 and 3.                                           *)
(***************************************************************************)
StoreOne(m) ==
    /\ resp = "open"
    /\ m \in pending
    /\ Source \in loc[m]
    /\ Target \in loc[m]
    /\ ~flagged[m]
    /\ flagged' = [flagged EXCEPT ![m] = TRUE]
    /\ UNCHANGED << loc, pending, resp >>

(***************************************************************************)
(* Step 3. The source copy goes, and the server is done with this message.  *)
(***************************************************************************)
ExpungeOne(m) ==
    /\ resp = "open"
    /\ m \in pending
    /\ flagged[m]
    /\ loc' = [loc EXCEPT ![m] = loc[m] \ {Source}]
    /\ flagged' = [flagged EXCEPT ![m] = FALSE]
    /\ pending' = pending \ {m}
    /\ UNCHANGED resp

(***************************************************************************)
(* The failure branch, guarded so it can only fire on a message nothing has *)
(* touched yet.  A server cannot claim it left a message alone after it has *)
(* already copied it.                                                       *)
(***************************************************************************)
LeaveOne(m) ==
    /\ resp = "open"
    /\ m \in pending
    /\ loc[m] = {Source}
    /\ ~flagged[m]
    /\ pending' = pending \ {m}
    /\ UNCHANGED << loc, flagged, resp >>

Next == \/ \E m \in Msg : \/ CopyOne(m)
                          \/ StoreOne(m)
                          \/ ExpungeOne(m)
                          \/ LeaveOne(m)
        \/ \E r \in {"ok", "no"} : Reply(r)
        \/ Abort

Spec == Init /\ [][Next]_vars

===========================================================================
