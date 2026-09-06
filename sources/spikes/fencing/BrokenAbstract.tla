--------------------------- MODULE BrokenAbstract ---------------------------
(***************************************************************************)
(* The same broken system with the clock DELETED.                          *)
(*                                                                         *)
(* This is the modelling decision the whole problem turns on. A lease has a *)
(* duration, so the reflex is to model a clock. But nothing in the          *)
(* requirement mentions a number: the safety property asks about the ORDER  *)
(* of expiry against the client's progress, never about how long either     *)
(* took. So the clock, `expiry', and the constants MaxTime and Lease all    *)
(* collapse into one nondeterministic action:                              *)
(*                                                                         *)
(*     Expire == owner # NoClient /\ owner' = NoClient                     *)
(*                                                                         *)
(* which says a standing lease may lapse at any moment, and says nothing    *)
(* about when. Three variables and two constants go away. Broken.tla and    *)
(* this file are checked against the same property, so the cost of the      *)
(* clock is the difference between their two rows in REPORT.md.            *)
(*                                                                         *)
(* What is LOST: nothing that this property can see. What would bring the  *)
(* clock back is a requirement with a number in it -- "a lease is never     *)
(* granted twice inside one lease duration", or any bound on how long a     *)
(* client may be locked out.                                               *)
(***************************************************************************)
EXTENDS Naturals, Sequences, FiniteSets

CONSTANTS Clients, NoClient

MaxToken == Cardinality(Clients)

VARIABLES owner, nextTok, pc, tok, log

vars == << owner, nextTok, pc, tok, log >>

TypeOK ==
    /\ owner \in Clients \cup {NoClient}
    /\ nextTok \in 1..(MaxToken + 1)
    /\ pc \in [Clients -> {"idle", "held", "done"}]
    /\ tok \in [Clients -> 0..MaxToken]
    /\ \A i \in 1..Len(log) : log[i] \in 1..MaxToken

Init ==
    /\ owner = NoClient
    /\ nextTok = 1
    /\ pc = [c \in Clients |-> "idle"]
    /\ tok = [c \in Clients |-> 0]
    /\ log = << >>

Acquire(c) ==
    /\ pc[c] = "idle"
    /\ owner = NoClient
    /\ owner' = c
    /\ tok' = [tok EXCEPT ![c] = nextTok]
    /\ nextTok' = nextTok + 1
    /\ pc' = [pc EXCEPT ![c] = "held"]
    /\ UNCHANGED << log >>

\* The clock, the deadline and the arithmetic, all of it, reduced to this.
Expire ==
    /\ owner # NoClient
    /\ owner' = NoClient
    /\ UNCHANGED << nextTok, pc, tok, log >>

Write(c) ==
    /\ pc[c] = "held"
    /\ log' = Append(log, tok[c])
    /\ pc' = [pc EXCEPT ![c] = "done"]
    /\ UNCHANGED << owner, nextTok, tok >>

Next ==
    \/ Expire
    \/ \E c \in Clients : Acquire(c) \/ Write(c)

Spec == Init /\ [][Next]_vars

-----------------------------------------------------------------------------

NoStaleWrite ==
    \A i \in 1..Len(log) :
        \A j \in 1..Len(log) :
            i < j => log[i] < log[j]

TwoWritesLand == Len(log) < 2

=============================================================================
