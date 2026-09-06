------------------------------ MODULE FencedGE ------------------------------
(***************************************************************************)
(* Fenced.tla with the off-by-one an implementer actually writes: the      *)
(* storage service accepts on tok >= maxTok instead of tok > maxTok.       *)
(*                                                                         *)
(* Read the guard as a rejection rule and the slip is obvious -- "refuse   *)
(* anything BELOW the highest I have seen" instead of "at or below". The   *)
(* question this module exists to answer is whether that slip is reachable *)
(* here. See REPORT.md. The answer is not the one I expected.              *)
(***************************************************************************)
EXTENDS Naturals, Sequences, FiniteSets

CONSTANTS Clients, NoClient, MaxTime, Lease

MaxToken == Cardinality(Clients)

VARIABLES clock, owner, expiry, nextTok, pc, tok, log, maxTok

vars == << clock, owner, expiry, nextTok, pc, tok, log, maxTok >>

TypeOK ==
    /\ clock \in 0..MaxTime
    /\ owner \in Clients \cup {NoClient}
    /\ expiry \in 0..(MaxTime + Lease)
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

\* >= where Fenced.tla has >. The only difference between the two modules.
Write(c) ==
    /\ pc[c] = "held"
    /\ tok[c] >= maxTok
    /\ log' = Append(log, tok[c])
    /\ maxTok' = tok[c]
    /\ pc' = [pc EXCEPT ![c] = "done"]
    /\ UNCHANGED << clock, owner, expiry, nextTok, tok >>

Reject(c) ==
    /\ pc[c] = "held"
    /\ tok[c] < maxTok
    /\ pc' = [pc EXCEPT ![c] = "failed"]
    /\ UNCHANGED << clock, owner, expiry, nextTok, tok, log, maxTok >>

Tick ==
    /\ clock < MaxTime
    /\ clock' = clock + 1
    /\ UNCHANGED << owner, expiry, nextTok, pc, tok, log, maxTok >>

Next ==
    \/ Tick
    \/ \E c \in Clients : Acquire(c) \/ Write(c) \/ Reject(c)

Spec == Init /\ [][Next]_vars

-----------------------------------------------------------------------------

\* Non-strict, to match the guard. The strict form NoStaleWrite would call a
\* duplicate token a violation on shape alone rather than on staleness, and
\* the question here is whether the >= guard admits a STALE write.
NoStaleWrite ==
    \A i \in 1..Len(log) :
        \A j \in 1..Len(log) :
            i < j => log[i] <= log[j]

TwoWritesLand == Len(log) < 2

=============================================================================
