--------------------------- MODULE BrokenUnbounded --------------------------
(***************************************************************************)
(* Broken.tla with the guard taken off Tick.                               *)
(*                                                                         *)
(* The state space is infinite, as in FencedUnbounded.tla. The one         *)
(* difference is that this one has a counterexample, and TLC searches      *)
(* breadth-first, so it reaches the violation at a shallow depth and stops. *)
(*                                                                         *)
(* Expect exit 12 in about the same time as the bounded run. An unbounded  *)
(* clock costs nothing when the answer is a counterexample, and costs      *)
(* everything when the answer is a proof. That asymmetry is the finding.   *)
(***************************************************************************)
EXTENDS Naturals, Sequences, FiniteSets

CONSTANTS Clients, NoClient, Lease

MaxToken == Cardinality(Clients)

VARIABLES clock, owner, expiry, nextTok, pc, tok, log

vars == << clock, owner, expiry, nextTok, pc, tok, log >>

Init ==
    /\ clock = 0
    /\ owner = NoClient
    /\ expiry = 0
    /\ nextTok = 1
    /\ pc = [c \in Clients |-> "idle"]
    /\ tok = [c \in Clients |-> 0]
    /\ log = << >>

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

Write(c) ==
    /\ pc[c] = "held"
    /\ log' = Append(log, tok[c])
    /\ pc' = [pc EXCEPT ![c] = "done"]
    /\ UNCHANGED << clock, owner, expiry, nextTok, tok >>

Tick ==
    /\ clock' = clock + 1
    /\ UNCHANGED << owner, expiry, nextTok, pc, tok, log >>

Next ==
    \/ Tick
    \/ \E c \in Clients : Acquire(c) \/ Write(c)

Spec == Init /\ [][Next]_vars

-----------------------------------------------------------------------------

NoStaleWrite ==
    \A i \in 1..Len(log) :
        \A j \in 1..Len(log) :
            i < j => log[i] < log[j]

=============================================================================
