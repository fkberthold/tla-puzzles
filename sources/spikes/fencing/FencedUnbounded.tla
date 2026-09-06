--------------------------- MODULE FencedUnbounded --------------------------
(***************************************************************************)
(* Fenced.tla with the guard taken off Tick, so the clock climbs forever.   *)
(*                                                                         *)
(* The point is to find out whether the BOUND is load-bearing or whether    *)
(* the rest of the system happens to be finite without it. It is            *)
(* load-bearing: `clock' alone makes the reachable state space infinite,    *)
(* whatever the clients do, because Tick is enabled in every state.         *)
(*                                                                         *)
(* Expect this run to hit its wall-clock budget and exit 124. That is not   *)
(* a verdict about the fence, it is a verdict about the clock.              *)
(***************************************************************************)
EXTENDS Naturals, Sequences, FiniteSets

CONSTANTS Clients, NoClient, Lease

MaxToken == Cardinality(Clients)

VARIABLES clock, owner, expiry, nextTok, pc, tok, log, maxTok

vars == << clock, owner, expiry, nextTok, pc, tok, log, maxTok >>

TypeOK ==
    /\ clock \in Nat
    /\ owner \in Clients \cup {NoClient}
    /\ expiry \in Nat
    /\ nextTok \in 1..(MaxToken + 1)
    /\ pc \in [Clients -> {"idle", "held", "done", "failed"}]
    /\ tok \in [Clients -> 0..MaxToken]
    /\ maxTok \in 0..MaxToken
    /\ \A i \in 1..Len(log) : log[i] \in 1..MaxToken

Init ==
    /\ clock = 0
    /\ owner = NoClient
    /\ expiry = 0
    /\ nextTok = 1
    /\ pc = [c \in Clients |-> "idle"]
    /\ tok = [c \in Clients |-> 0]
    /\ log = << >>
    /\ maxTok = 0

LeaseFree == owner = NoClient \/ clock >= expiry

Acquire(c) ==
    /\ pc[c] = "idle"
    /\ LeaseFree
    /\ owner' = c
    /\ expiry' = clock + Lease
    /\ tok' = [tok EXCEPT ![c] = nextTok]
    /\ nextTok' = nextTok + 1
    /\ pc' = [pc EXCEPT ![c] = "held"]
    /\ UNCHANGED << clock, log, maxTok >>

Write(c) ==
    /\ pc[c] = "held"
    /\ tok[c] > maxTok
    /\ log' = Append(log, tok[c])
    /\ maxTok' = tok[c]
    /\ pc' = [pc EXCEPT ![c] = "done"]
    /\ UNCHANGED << clock, owner, expiry, nextTok, tok >>

Reject(c) ==
    /\ pc[c] = "held"
    /\ tok[c] <= maxTok
    /\ pc' = [pc EXCEPT ![c] = "failed"]
    /\ UNCHANGED << clock, owner, expiry, nextTok, tok, log, maxTok >>

\* No guard. This is the only difference from Fenced.tla.
Tick ==
    /\ clock' = clock + 1
    /\ UNCHANGED << owner, expiry, nextTok, pc, tok, log, maxTok >>

Next ==
    \/ Tick
    \/ \E c \in Clients : Acquire(c) \/ Write(c) \/ Reject(c)

Spec == Init /\ [][Next]_vars

-----------------------------------------------------------------------------

NoStaleWrite ==
    \A i \in 1..Len(log) :
        \A j \in 1..Len(log) :
            i < j => log[i] < log[j]

=============================================================================
