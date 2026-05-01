---- MODULE AbstractCounter ----
(***************************************************************************)
(* The ABSTRACT spec for the distributed counter.                          *)
(*                                                                         *)
(* A single global counter `c` advances from 0 to N one tick at a time.    *)
(* When the counter reaches N, a separate Finish action sets `done`.       *)
(*                                                                         *)
(* This is the simplest possible model of "count to N then signal done."   *)
(* The concrete spec (DistributedCounter) refines this one.                *)
(***************************************************************************)
EXTENDS Integers

CONSTANT
  \* @type: Int;
  N

ASSUME N \in Nat

VARIABLES
  \* @type: Int;
  c,
  \* @type: Bool;
  done

vars == <<c, done>>

TypeOK ==
  /\ c \in 0..N
  /\ done \in BOOLEAN

Init ==
  /\ c = 0
  /\ done = FALSE

\* One tick advances the counter while it has not reached N.
Tick ==
  /\ c < N
  /\ c' = c + 1
  /\ UNCHANGED done

\* Once the counter reaches N, the system signals done.
Finish ==
  /\ c = N
  /\ ~done
  /\ done' = TRUE
  /\ UNCHANGED c

\* Terminal stutter once `done` is true, so the spec doesn't deadlock.
DoneStutter == done /\ UNCHANGED vars

Next == Tick \/ Finish \/ DoneStutter

Spec ==
  /\ Init
  /\ [][Next]_vars
  /\ WF_vars(Tick)
  /\ WF_vars(Finish)

\* Liveness: the counter eventually signals done.
EventuallyDone == <>done

================================
