--------------------------- MODULE FencedRestart ---------------------------
(***************************************************************************)
(* The >= off-by-one, under the one condition that makes it bite.          *)
(*                                                                         *)
(* FencedGE.tla exits 0, which surprised me. The reason is that the lock   *)
(* service there issues a STRICTLY increasing token on every grant, so no  *)
(* two live tokens are ever equal and >= and > can never disagree. The     *)
(* off-by-one is real and unreachable, which is the worst kind: it survives *)
(* review, it survives the model check, and it waits.                      *)
(*                                                                         *)
(* What it waits for is a repeated token. This module supplies the ordinary *)
(* way that happens: the lock service restarts and its counter goes back to *)
(* 1. The storage service does not restart, because it is a different      *)
(* component -- that asymmetry is the whole problem.                       *)
(*                                                                         *)
(* CONSTANT Strict switches the guard, so one module answers both halves.  *)
(*   Strict = TRUE   the guard is  tok > maxTok    (Fenced.tla's rule)     *)
(*   Strict = FALSE  the guard is  tok >= maxTok   (the off-by-one)        *)
(*                                                                         *)
(* AUXILIARY VARIABLES. Once tokens repeat, the token log stops being able *)
(* to say which write was stale: <<1, 1>> is either two grants in order or *)
(* a superseded writer landing behind its successor, and nothing in the    *)
(* storage service can tell them apart. So the property is stated over     *)
(* `gs', a grant sequence number the model keeps and no component reads.   *)
(* The fence still runs on `tok'. Auxiliary state carrying a property that *)
(* the real state cannot express is normal practice. It is here because    *)
(* the observable log really did lose the information.                     *)
(***************************************************************************)
EXTENDS Naturals, Sequences, FiniteSets

CONSTANTS Clients, NoClient, MaxTime, Lease, Strict

NumClients == Cardinality(Clients)

VARIABLES
    clock, owner, expiry, nextTok, pc, tok, maxTok,
    gs,         \* AUXILIARY. Grant sequence number per client, never reset.
    log,        \* AUXILIARY. The gs of each accepted write, in order.
    restarted   \* the lock service is allowed to lose its counter once

vars == << clock, owner, expiry, nextTok, pc, tok, maxTok, gs, log, restarted >>

TypeOK ==
    /\ clock \in 0..MaxTime
    /\ owner \in Clients \cup {NoClient}
    /\ expiry \in 0..(MaxTime + Lease)
    /\ nextTok \in 1..(NumClients + 1)
    /\ pc \in [Clients -> {"idle", "held", "done", "failed"}]
    /\ tok \in [Clients -> 0..NumClients]
    /\ maxTok \in 0..NumClients
    /\ gs \in [Clients -> 0..NumClients]
    /\ restarted \in BOOLEAN
    /\ \A i \in 1..Len(log) : log[i] \in 1..NumClients

Init ==
    /\ clock = 0
    /\ owner = NoClient
    /\ expiry = 0
    /\ nextTok = 1
    /\ pc = [c \in Clients |-> "idle"]
    /\ tok = [c \in Clients |-> 0]
    /\ maxTok = 0
    /\ gs = [c \in Clients |-> 0]
    /\ log = << >>
    /\ restarted = FALSE

LeaseFree == owner = NoClient \/ clock >= expiry

\* The grant sequence number counts grants over all time, so it is one more
\* than however many clients have already been served. Deriving it rather
\* than carrying a counter keeps one variable out of the state space.
NextGS == Cardinality({c \in Clients : gs[c] # 0}) + 1

Acquire(c) ==
    /\ pc[c] = "idle"
    /\ LeaseFree
    /\ owner' = c
    /\ expiry' = clock + Lease
    /\ tok' = [tok EXCEPT ![c] = nextTok]
    /\ gs' = [gs EXCEPT ![c] = NextGS]
    /\ nextTok' = nextTok + 1
    /\ pc' = [pc EXCEPT ![c] = "held"]
    /\ UNCHANGED << clock, log, maxTok, restarted >>

\* The lock service comes back with an empty counter. Its clients and the
\* storage service carry on as if nothing happened, which is the point.
LockRestart ==
    /\ ~restarted
    /\ restarted' = TRUE
    /\ nextTok' = 1
    /\ owner' = NoClient
    /\ expiry' = 0
    /\ UNCHANGED << clock, pc, tok, maxTok, gs, log >>

Accepts(c) == IF Strict THEN tok[c] > maxTok ELSE tok[c] >= maxTok

Write(c) ==
    /\ pc[c] = "held"
    /\ Accepts(c)
    /\ log' = Append(log, gs[c])
    /\ maxTok' = tok[c]
    /\ pc' = [pc EXCEPT ![c] = "done"]
    /\ UNCHANGED << clock, owner, expiry, nextTok, tok, gs, restarted >>

Reject(c) ==
    /\ pc[c] = "held"
    /\ ~Accepts(c)
    /\ pc' = [pc EXCEPT ![c] = "failed"]
    /\ UNCHANGED << clock, owner, expiry, nextTok, tok, maxTok, gs, log, restarted >>

Tick ==
    /\ clock < MaxTime
    /\ clock' = clock + 1
    /\ UNCHANGED << owner, expiry, nextTok, pc, tok, maxTok, gs, log, restarted >>

Next ==
    \/ Tick
    \/ LockRestart
    \/ \E c \in Clients : Acquire(c) \/ Write(c) \/ Reject(c)

Spec == Init /\ [][Next]_vars

-----------------------------------------------------------------------------

\* No write lands behind one from a later grant. Stated over the grant
\* sequence, which survives the counter reset that the token does not.
NoStaleWrite ==
    \A i \in 1..Len(log) :
        \A j \in 1..Len(log) :
            i < j => log[i] < log[j]

\* Liveness in disguise, as an invariant. FALSE means some run got a write
\* through. TRUE would mean the fence rejects every client after a restart.
SomeWriteLands == Len(log) = 0

\* The other half of the restart story, and the reason a strict fence is not
\* free. The storage service kept its high-water mark across the restart, so
\* it can now refuse the client that legitimately holds a LIVE lease -- not a
\* stale writer, the current one. Availability written as a state invariant,
\* because the offending state is visible rather than only the transition.
\* MCFencedRestartLockout.tla checks it under Strict = TRUE and it is FALSE.
LiveHolderNeverRejected ==
    \A c \in Clients :
        pc[c] = "failed" => ~(owner = c /\ clock < expiry)

=============================================================================
