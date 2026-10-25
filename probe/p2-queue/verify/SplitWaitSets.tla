---------------------------- MODULE SplitWaitSets ---------------------------
(***************************************************************************)
(* REFERENCE SOLUTION for probe item p2-queue. Written for this probe, not  *)
(* copied from any published module. Withheld from the delivered tree.      *)
(*                                                                         *)
(* THE DECISION THIS MODULE MAKES, and it is the decision the brief forces: *)
(* a hand-off wakes ONE sleeping thread of the other kind, not all of them. *)
(* WakeOneConsumer and WakeOneProducer each drop a single thread out of a    *)
(* wait set. verify/WrongNotifyAll.tla holds the other reading and the      *)
(* verdict it gets.                                                         *)
(***************************************************************************)
EXTENDS Naturals, Sequences

CONSTANTS Producers, Consumers, BufCapacity

VARIABLES buffer, waitSetP, waitSetC

vars == <<buffer, waitSetP, waitSetC>>

TypeOK ==
  /\ buffer \in Seq(Producers)
  /\ Len(buffer) \in 0..BufCapacity
  /\ waitSetP \subseteq Producers
  /\ waitSetC \subseteq Consumers

Init ==
  /\ buffer = <<>>
  /\ waitSetP = {}
  /\ waitSetC = {}

-----------------------------------------------------------------------------
(* One sleeping thread of the other kind gets woken, and only if one is     *)
(* sleeping. Both of these are actions: each one writes a primed variable.  *)

WakeOneConsumer ==
  IF waitSetC # {}
  THEN \E t \in waitSetC : waitSetC' = waitSetC \ {t}
  ELSE waitSetC' = waitSetC

WakeOneProducer ==
  IF waitSetP # {}
  THEN \E t \in waitSetP : waitSetP' = waitSetP \ {t}
  ELSE waitSetP' = waitSetP

-----------------------------------------------------------------------------

Put(p) ==
  /\ p \notin waitSetP
  /\ \/ /\ Len(buffer) < BufCapacity
        /\ buffer' = Append(buffer, p)
        /\ WakeOneConsumer
        /\ waitSetP' = waitSetP
     \/ /\ Len(buffer) = BufCapacity
        /\ waitSetP' = waitSetP \cup {p}
        /\ UNCHANGED <<buffer, waitSetC>>

Get(c) ==
  /\ c \notin waitSetC
  /\ \/ /\ buffer # <<>>
        /\ buffer' = Tail(buffer)
        /\ WakeOneProducer
        /\ waitSetC' = waitSetC
     \/ /\ buffer = <<>>
        /\ waitSetC' = waitSetC \cup {c}
        /\ UNCHANGED <<buffer, waitSetP>>

Next ==
  \/ \E p \in Producers : Put(p)
  \/ \E c \in Consumers : Get(c)

Spec == Init /\ [][Next]_vars

NoDeadlock == (waitSetP \cup waitSetC) # (Producers \cup Consumers)

-----------------------------------------------------------------------------
(* The refinement mapping. The two wait sets are disjoint, because no thread *)
(* is both a producer and a consumer, so their union is the one wait set the *)
(* requirement module talks about.                                           *)

BQ == INSTANCE BlockingQueue
        WITH Producers <- Producers,
             Consumers <- Consumers,
             BufCapacity <- BufCapacity,
             buffer <- buffer,
             waitSet <- (waitSetP \cup waitSetC)

Refines == BQ!Spec

=============================================================================
