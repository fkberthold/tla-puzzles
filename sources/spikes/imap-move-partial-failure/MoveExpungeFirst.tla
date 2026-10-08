------------------------- MODULE MoveExpungeFirst -------------------------
(***************************************************************************)
(* THE DECOMPOSITION RUN BACKWARDS, which is how a message gets lost.       *)
(*                                                                          *)
(* MoveDecomposed copies and then expunges, so its intermediate state has   *)
(* the message in both mailboxes.  Swap the order and the intermediate      *)
(* state has it in neither.  That breaks clause 2, the safety floor, which  *)
(* nothing in the other two models can reach.                               *)
(*                                                                          *)
(* The spike needs this model to answer a question about the clause set     *)
(* rather than about any real server.  The survey at sources/rfcs.md found  *)
(* field bug reports on the duplicate side only, and no published           *)
(* server-side bug losing a message outright.  So the state clause 2 rules  *)
(* out is the one the field has no instance of, and reaching it takes a     *)
(* server nobody wrote.  Writing it is cheap and knowing that is worth it.  *)
(***************************************************************************)
EXTENDS MoveBase

(***************************************************************************)
(* Step 1 of the wrong order. The source copy goes first, and now the       *)
(* message is in no mailbox at all.                                         *)
(***************************************************************************)
RemoveOne(m) ==
    /\ resp = "open"
    /\ m \in pending
    /\ Source \in loc[m]
    /\ Target \notin loc[m]
    /\ loc' = [loc EXCEPT ![m] = loc[m] \ {Source}]
    /\ UNCHANGED << flagged, pending, resp >>

(***************************************************************************)
(* Step 2. The target copy lands, and the message exists again.             *)
(***************************************************************************)
AppendOne(m) ==
    /\ resp = "open"
    /\ m \in pending
    /\ Source \notin loc[m]
    /\ Target \notin loc[m]
    /\ loc' = [loc EXCEPT ![m] = loc[m] \cup {Target}]
    /\ pending' = pending \ {m}
    /\ UNCHANGED << flagged, resp >>

LeaveOne(m) ==
    /\ resp = "open"
    /\ m \in pending
    /\ loc[m] = {Source}
    /\ pending' = pending \ {m}
    /\ UNCHANGED << loc, flagged, resp >>

Next == \/ \E m \in Msg : \/ RemoveOne(m)
                          \/ AppendOne(m)
                          \/ LeaveOne(m)
        \/ \E r \in {"ok", "no"} : Reply(r)
        \/ Abort

Spec == Init /\ [][Next]_vars

===========================================================================
