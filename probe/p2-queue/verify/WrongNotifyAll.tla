--------------------------- MODULE WrongNotifyAll ---------------------------
(***************************************************************************)
(* DELIBERATELY WRONG solution for probe item p2-queue, and the reason the   *)
(* grader is worth running at all. A grader that passes everything measures  *)
(* nothing.                                                                 *)
(*                                                                         *)
(* It is SplitWaitSets with the hand-off widened. A put empties the consumer *)
(* wait set rather than taking one thread out of it, which is the other      *)
(* reading of the two requirements the brief puts next to each other: no     *)
(* sleeping consumer may stay asleep while the queue holds an entry.         *)
(*                                                                         *)
(* The requirement module admits a hand-off that wakes at most one thread.   *)
(* So the first state with two sleeping consumers and a put after it is a    *)
(* step the requirement has no counterpart for, and the refinement breaks.   *)
(* It takes two consumers to see it. At one consumer both readings agree.    *)
(*                                                                         *)
(* EXPECTED VERDICT: REFINEMENT_VIOLATED, exit 22.                          *)
(***************************************************************************)
EXTENDS Naturals, Sequences

CONSTANTS Producers, Consumers, BufCapacity

VARIABLES buffer, waitSetP, waitSetC

vars == <<buffer, waitSetP, waitSetC>>

Init ==
  /\ buffer = <<>>
  /\ waitSetP = {}
  /\ waitSetC = {}

\* THE TWO LINES THAT DIFFER from the reference solution.
WakeAllConsumers == waitSetC' = {}
WakeAllProducers == waitSetP' = {}

Put(p) ==
  /\ p \notin waitSetP
  /\ \/ /\ Len(buffer) < BufCapacity
        /\ buffer' = Append(buffer, p)
        /\ WakeAllConsumers
        /\ waitSetP' = waitSetP
     \/ /\ Len(buffer) = BufCapacity
        /\ waitSetP' = waitSetP \cup {p}
        /\ UNCHANGED <<buffer, waitSetC>>

Get(c) ==
  /\ c \notin waitSetC
  /\ \/ /\ buffer # <<>>
        /\ buffer' = Tail(buffer)
        /\ WakeAllProducers
        /\ waitSetC' = waitSetC
     \/ /\ buffer = <<>>
        /\ waitSetC' = waitSetC \cup {c}
        /\ UNCHANGED <<buffer, waitSetP>>

Next ==
  \/ \E p \in Producers : Put(p)
  \/ \E c \in Consumers : Get(c)

Spec == Init /\ [][Next]_vars

BQ == INSTANCE BlockingQueue
        WITH Producers <- Producers,
             Consumers <- Consumers,
             BufCapacity <- BufCapacity,
             buffer <- buffer,
             waitSet <- (waitSetP \cup waitSetC)

Refines == BQ!Spec

=============================================================================
