---------------------------- MODULE MoveAtomic ----------------------------
(***************************************************************************)
(* THE CONFORMING SERVER, and the reference spec for the seeded-bug matrix. *)
(*                                                                          *)
(* RFC 9051 section 6.4.8 says a MOVE "has the same effect for each message *)
(* as this sequence" of COPY, STORE +FLAGS.SILENT \DELETED and UID EXPUNGE, *)
(* "[a]lthough the effect of the MOVE is the same as the preceding steps,   *)
(* the semantics are not identical: the intermediate states produced by     *)
(* those steps do not occur".  So the move is atomic PER MESSAGE and not    *)
(* over the set, and this module is the direct reading of that: one step    *)
(* per message, no intermediate state, and a failure that lands on any      *)
(* message without stopping the rest.                                       *)
(*                                                                          *)
(* `flagged` is never set anywhere here, which is not an oversight.  It is  *)
(* the same section's "the \Deleted flag MUST NOT be set for any message",  *)
(* so the variable sitting constantly FALSE is the requirement rather than  *)
(* a frozen state component.  See REPORT.md.                                *)
(*                                                                          *)
(* This module defines no invariant of its own.  The three clauses come     *)
(* from MoveBase, and the seeded-bug matrix needs the learner's property to *)
(* be the only thing supplying one.                                        *)
(***************************************************************************)
EXTENDS MoveBase

\* SEEDED VARIANT: leave-half-moves. WRONG ON PURPOSE.
\*
\* LeaveOne is the branch where the server fails on one message and leaves it
\* alone. Here it drops the source copy instead, so the FAILURE path is what
\* loses the message.
\*
\* Same clause pair as expunge-without-copy and a different route to it. The
\* whole paragraph is about the failure path, so a property that only ever
\* watched the success path is the mistake worth seeding.

(***************************************************************************)
(* The server moves one message, whole.  No state between.                  *)
(***************************************************************************)
MoveOne(m) ==
    /\ resp = "open"
    /\ m \in pending
    /\ loc' = [loc EXCEPT ![m] = {Target}]
    /\ pending' = pending \ {m}
    /\ UNCHANGED << flagged, resp >>

(***************************************************************************)
(* Or it fails on this one message and leaves it exactly as it was.  That   *)
(* is the "unaffected" branch of sentence 1, and it is where the per-message *)
(* granularity lives: `pending` loses one element either way, so a failure  *)
(* on one message says nothing about the others.                            *)
(***************************************************************************)
LeaveOne(m) ==
    /\ resp = "open"
    /\ m \in pending
    /\ pending' = pending \ {m}
    /\ loc' = [loc EXCEPT ![m] = {}]
    /\ UNCHANGED << flagged, resp >>

Next == \/ \E m \in Msg : MoveOne(m) \/ LeaveOne(m)
        \/ \E r \in {"ok", "no"} : Reply(r)
        \/ Abort

Spec == Init /\ [][Next]_vars

===========================================================================
