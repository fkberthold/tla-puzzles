------------------------------- MODULE Broken -------------------------------
(***************************************************************************)
(* The lease-expiry problem WITHOUT fencing. DDIA figure 8-4.               *)
(*                                                                          *)
(* Three components. A lock service that grants a lease with a deadline, a  *)
(* set of clients that acquire then write, and a storage service that       *)
(* accepts whatever it is handed. The storage service knows nothing about   *)
(* leases, which is the whole point: it is a different component.           *)
(*                                                                          *)
(* TIME. `clock' is a bounded counter and `Tick' is an ordinary action of   *)
(* Next. The pause that causes the bug is NOT modelled. It does not have to *)
(* be. A client sitting in "held" while Tick fires is a paused              *)
(* client, and TLA+ gives that interleaving away for free.                  *)
(*                                                                          *)
(* THE PROPERTY. `NoStaleWrite' says the tokens in the storage log are      *)
(* strictly increasing, so no write ever lands behind a newer one. It is    *)
(* false here and TLC exits 12.                                             *)
(***************************************************************************)
EXTENDS Naturals, Sequences, FiniteSets

CONSTANTS
    Clients,    \* set of client identities
    NoClient,   \* a value outside Clients, meaning the lease is unheld
    MaxTime,    \* the clock stops here, which is what makes the space finite
    Lease       \* how many ticks a grant is good for

\* One token per grant, and a client grabs at most one grant, so this bounds it.
MaxToken == Cardinality(Clients)

VARIABLES
    clock,      \* lock service and clients share one clock
    owner,      \* lock service: who holds the lease
    expiry,     \* lock service: the clock value the lease dies at
    nextTok,    \* lock service: the next token to hand out
    pc,         \* client c: idle, held, done
    tok,        \* client c: the token it was handed, 0 before it has one
    log         \* storage service: the tokens of the writes it accepted

vars == << clock, owner, expiry, nextTok, pc, tok, log >>

TypeOK ==
    /\ clock \in 0..MaxTime
    /\ owner \in Clients \cup {NoClient}
    /\ expiry \in 0..(MaxTime + Lease)
    /\ nextTok \in 1..(MaxToken + 1)
    /\ pc \in [Clients -> {"idle", "held", "done"}]
    /\ tok \in [Clients -> 0..MaxToken]
    /\ \A i \in 1..Len(log) : log[i] \in 1..MaxToken

Init ==
    /\ clock = 0
    /\ owner = NoClient
    /\ expiry = 0
    /\ nextTok = 1
    /\ pc = [c \in Clients |-> "idle"]
    /\ tok = [c \in Clients |-> 0]
    /\ log = << >>

\* The lock service is CORRECT. It grants only when nothing holds the lease or
\* the standing lease has run out. The defect under study is downstream.
LeaseFree == owner = NoClient \/ clock >= expiry

Acquire(c) ==
    /\ pc[c] = "idle"
    /\ LeaseFree
    /\ owner' = c
    /\ expiry' = clock + Lease
    /\ tok' = [tok EXCEPT ![c] = nextTok]
    /\ nextTok' = nextTok + 1
    /\ pc' = [pc EXCEPT ![c] = "held"]
    /\ UNCHANGED << clock, log >>

\* The storage service has no idea any of this happened. It appends.
Write(c) ==
    /\ pc[c] = "held"
    /\ log' = Append(log, tok[c])
    /\ pc' = [pc EXCEPT ![c] = "done"]
    /\ UNCHANGED << clock, owner, expiry, nextTok, tok >>

Tick ==
    /\ clock < MaxTime
    /\ clock' = clock + 1
    /\ UNCHANGED << owner, expiry, nextTok, pc, tok, log >>

Next ==
    \/ Tick
    \/ \E c \in Clients : Acquire(c) \/ Write(c)

Spec == Init /\ [][Next]_vars

-----------------------------------------------------------------------------

\* The requirement. Grants are handed out in increasing token order, so a
\* write that lands behind one with a higher token came from a lease that had
\* already been superseded. That is the stale write.
NoStaleWrite ==
    \A i \in 1..Len(log) :
        \A j \in 1..Len(log) :
            i < j => log[i] < log[j]

\* The brief's wording said "never accepts a write from a client whose lease
\* has expired". Stated literally that is an ACTION property, not a state
\* invariant, because expiry is a fact about the instant of the write and not
\* about any state you can look at afterwards. MCBrokenAction.tla checks this
\* form, at a different TLC exit code. See REPORT.md.
LeaseLive(c) == owner = c /\ clock < expiry
NoExpiredWrite ==
    [][ \A c \in Clients : (pc[c] = "held" /\ pc'[c] = "done") => LeaseLive(c) ]_vars

\* Vacuity witness: this is FALSE on a healthy model, and its counterexample
\* is a run in which two writes actually landed. An invariant nobody can
\* violate proves nothing about a storage service that accepts nothing.
TwoWritesLand == Len(log) < 2

=============================================================================
