------------------------------- MODULE Fenced -------------------------------
(***************************************************************************)
(* Broken.tla with fencing tokens. DDIA figure 8-5.                        *)
(*                                                                         *)
(* The lock service already handed out a monotonically increasing token per *)
(* grant, in Broken.tla, and that was not enough. The change here is        *)
(* entirely in the storage service: it remembers the highest token it has   *)
(* accepted and refuses anything at or below it.                           *)
(*                                                                         *)
(* One new variable, `maxTok'. One new conjunct in Write. One new action,   *)
(* Reject, because a real storage service returns an error rather than      *)
(* leaving the client hanging -- and without it a rejected client sits in   *)
(* "held" forever, which TLC reports as a deadlock and which would be a     *)
(* false alarm about a spec that is doing the right thing.                  *)
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

\* THE FIX, and all of it: tok[c] > maxTok.
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

Tick ==
    /\ clock < MaxTime
    /\ clock' = clock + 1
    /\ UNCHANGED << owner, expiry, nextTok, pc, tok, log, maxTok >>

Next ==
    \/ Tick
    \/ \E c \in Clients : Acquire(c) \/ Write(c) \/ Reject(c)

Spec == Init /\ [][Next]_vars

\* Only MCFencedLiveness.tla uses this. Without the fairness conjunct the
\* liveness property below is violated by a behaviour that simply stops,
\* which is a true counterexample and a useless one.
FairSpec == Spec /\ WF_vars(Next)

-----------------------------------------------------------------------------

NoStaleWrite ==
    \A i \in 1..Len(log) :
        \A j \in 1..Len(log) :
            i < j => log[i] < log[j]

\* Vacuity witness. FALSE on a healthy model, and the counterexample it
\* produces is a run where two writes really did land. Without this the
\* result above is compatible with a storage service that accepts nothing.
TwoWritesLand == Len(log) < 2

\* The brief's literal wording, as an action property. MCFencedAction.tla
\* checks it and it is FALSE here, which is not a defect in the fence. See
\* REPORT.md: fencing rules out a SUPERSEDED write, not an EXPIRED one, and
\* those two coincide only while nobody is waiting for the lease.
LeaseLive(c) == owner = c /\ clock < expiry
NoExpiredWrite ==
    [][ \A c \in Clients : (pc[c] = "held" /\ pc'[c] = "done") => LeaseLive(c) ]_vars

\* The price of the fence, stated. A client that got the lease eventually
\* gets its write in. This is FALSE, and it is the only property here that
\* needs fairness to say anything. MCFencedLiveness.tla checks it.
HeldEventuallyWrites ==
    \A c \in Clients : (pc[c] = "held") ~> (pc[c] = "done")

=============================================================================
