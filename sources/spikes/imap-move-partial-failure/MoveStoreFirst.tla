-------------------------- MODULE MoveStoreFirst --------------------------
(***************************************************************************)
(* THE THIRD ORDERING OF THE RFC'S THREE STEPS, and the one that shows      *)
(* clause 1 is not just clauses 2 and 3 under another name.                  *)
(*                                                                          *)
(* RFC 9051 section 6.4.8 lists COPY, then STORE +FLAGS.SILENT \DELETED,    *)
(* then UID EXPUNGE. MoveDecomposed runs them in that order and             *)
(* MoveExpungeFirst runs the expunge first. This one marks the source copy  *)
(* \Deleted before it copies anything, which is an ordinary way to write an *)
(* implementation: flag what you are about to move, move it, then reap.     *)
(*                                                                          *)
(* The state it reaches that the other two cannot is a message sitting in   *)
(* exactly one mailbox, carrying a \Deleted flag nobody asked for. It is    *)
(* not moved and it is not unaffected, so clause 1 fails. It is in at least *)
(* one mailbox and in no more than one, so clauses 2 and 3 both hold. That  *)
(* is the only reachable shape in this spike where clause 1 fails alone,    *)
(* and without it clause 1 would be exactly the conjunction of the other    *)
(* two.                                                                     *)
(*                                                                          *)
(* RFC 9051 section 6.4.8 forbids the state in its own words a few lines    *)
(* above the paragraph: "the \Deleted flag MUST NOT be set for any          *)
(* message".                                                                *)
(***************************************************************************)
EXTENDS MoveBase

(***************************************************************************)
(* Step 1 of this ordering. The source copy is marked and nothing has moved *)
(* yet.                                                                     *)
(***************************************************************************)
StoreOne(m) ==
    /\ resp = "open"
    /\ m \in pending
    /\ Source \in loc[m]
    /\ ~flagged[m]
    /\ flagged' = [flagged EXCEPT ![m] = TRUE]
    /\ UNCHANGED << loc, pending, resp >>

(***************************************************************************)
(* Step 2. The target copy lands.                                           *)
(***************************************************************************)
CopyOne(m) ==
    /\ resp = "open"
    /\ m \in pending
    /\ flagged[m]
    /\ Target \notin loc[m]
    /\ loc' = [loc EXCEPT ![m] = loc[m] \cup {Target}]
    /\ UNCHANGED << flagged, pending, resp >>

(***************************************************************************)
(* Step 3. The source copy goes and the flag goes with it.                  *)
(***************************************************************************)
ExpungeOne(m) ==
    /\ resp = "open"
    /\ m \in pending
    /\ flagged[m]
    /\ Target \in loc[m]
    /\ loc' = [loc EXCEPT ![m] = loc[m] \ {Source}]
    /\ flagged' = [flagged EXCEPT ![m] = FALSE]
    /\ pending' = pending \ {m}
    /\ UNCHANGED resp

LeaveOne(m) ==
    /\ resp = "open"
    /\ m \in pending
    /\ loc[m] = {Source}
    /\ ~flagged[m]
    /\ pending' = pending \ {m}
    /\ UNCHANGED << loc, flagged, resp >>

Next == \/ \E m \in Msg : \/ StoreOne(m)
                          \/ CopyOne(m)
                          \/ ExpungeOne(m)
                          \/ LeaveOne(m)
        \/ \E r \in {"ok", "no"} : Reply(r)
        \/ Abort

Spec == Init /\ [][Next]_vars

===========================================================================
