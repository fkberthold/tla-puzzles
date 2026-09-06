------------------------ MODULE IsoReadCommitted ------------------------
(***************************************************************************)
(* READ COMMITTED, taken as given.                                         *)
(*                                                                         *)
(* Two rules.                                                              *)
(*                                                                         *)
(*   1. A read returns the value committed at the moment of the read. No    *)
(*      snapshot: a transaction that reads the same key twice may see two   *)
(*      different values.                                                   *)
(*                                                                         *)
(*   2. A transaction's own writes are buffered and applied together when   *)
(*      it commits, so no other transaction ever sees half of them. There   *)
(*      is no conflict check: commit always succeeds.                      *)
(*                                                                         *)
(* What rule 2 leaves out is write-write BLOCKING. A real engine makes the  *)
(* second writer of a row wait for the first to finish. Blocking changes    *)
(* when a step may happen, never what a committed state may be, so leaving  *)
(* it out weakens no safety property. It does mean this module says nothing *)
(* about deadlock or throughput.                                            *)
(*                                                                         *)
(* Same API as IsoSerial and IsoSnapshot.                                   *)
(***************************************************************************)
EXTENDS Naturals, FiniteSets, TLC

CONSTANTS Key, Txn, Value

VARIABLES store,   \* committed state: [Key -> Value]
          wset,    \* per transaction pending writes, a function on a subset of Key
          state    \* per transaction lifecycle

IsoVars == <<store, wset, state>>

IsoTypeOK ==
  /\ store \in [Key -> Value]
  /\ state \in [Txn -> {"init", "running", "committed", "aborted"}]
  /\ \A t \in Txn : DOMAIN wset[t] \subseteq Key

IsoInit(s0) ==
  /\ store = s0
  /\ wset  = [t \in Txn |-> << >>]
  /\ state = [t \in Txn |-> "init"]

Running(t) == state[t] = "running"

Begin(t) ==
  /\ state[t] = "init"
  /\ state' = [state EXCEPT ![t] = "running"]
  /\ UNCHANGED <<store, wset>>

\* Rule 1: whatever is committed right now, and the transaction's own writes.
See(t, k) == IF k \in DOMAIN wset[t] THEN wset[t][k] ELSE store[k]

Put(t, k, v) ==
  /\ wset' = [wset EXCEPT ![t] = (k :> v) @@ wset[t]]
  /\ UNCHANGED <<store, state>>

Idle == UNCHANGED IsoVars

\* Rule 2: applied together, and never refused.
Finish(t) ==
  /\ store' = wset[t] @@ store
  /\ state' = [state EXCEPT ![t] = "committed"]
  /\ UNCHANGED wset

==========================================================================
