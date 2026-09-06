--------------------------- MODULE FencedAbstract ---------------------------
(***************************************************************************)
(* BrokenAbstract.tla with the fence. The clockless counterpart of         *)
(* Fenced.tla, checked against the same property, so the two pairs measure *)
(* the cost of modelling time as a number.                                 *)
(***************************************************************************)
EXTENDS Naturals, Sequences, FiniteSets

CONSTANTS Clients, NoClient

MaxToken == Cardinality(Clients)

VARIABLES owner, nextTok, pc, tok, log, maxTok

vars == << owner, nextTok, pc, tok, log, maxTok >>

TypeOK ==
    /\ owner \in Clients \cup {NoClient}
    /\ nextTok \in 1..(MaxToken + 1)
    /\ pc \in [Clients -> {"idle", "held", "done", "failed"}]
    /\ tok \in [Clients -> 0..MaxToken]
    /\ maxTok \in 0..MaxToken
    /\ \A i \in 1..Len(log) : log[i] \in 1..MaxToken

Init ==
    /\ owner = NoClient
    /\ nextTok = 1
    /\ pc = [c \in Clients |-> "idle"]
    /\ tok = [c \in Clients |-> 0]
    /\ log = << >>
    /\ maxTok = 0

Acquire(c) ==
    /\ pc[c] = "idle"
    /\ owner = NoClient
    /\ owner' = c
    /\ tok' = [tok EXCEPT ![c] = nextTok]
    /\ nextTok' = nextTok + 1
    /\ pc' = [pc EXCEPT ![c] = "held"]
    /\ UNCHANGED << log, maxTok >>

Expire ==
    /\ owner # NoClient
    /\ owner' = NoClient
    /\ UNCHANGED << nextTok, pc, tok, log, maxTok >>

Write(c) ==
    /\ pc[c] = "held"
    /\ tok[c] > maxTok
    /\ log' = Append(log, tok[c])
    /\ maxTok' = tok[c]
    /\ pc' = [pc EXCEPT ![c] = "done"]
    /\ UNCHANGED << owner, nextTok, tok >>

Reject(c) ==
    /\ pc[c] = "held"
    /\ tok[c] <= maxTok
    /\ pc' = [pc EXCEPT ![c] = "failed"]
    /\ UNCHANGED << owner, nextTok, tok, log, maxTok >>

Next ==
    \/ Expire
    \/ \E c \in Clients : Acquire(c) \/ Write(c) \/ Reject(c)

Spec == Init /\ [][Next]_vars

-----------------------------------------------------------------------------

NoStaleWrite ==
    \A i \in 1..Len(log) :
        \A j \in 1..Len(log) :
            i < j => log[i] < log[j]

TwoWritesLand == Len(log) < 2

=============================================================================
