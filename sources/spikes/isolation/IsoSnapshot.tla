--------------------------- MODULE IsoSnapshot ---------------------------
(***************************************************************************)
(* SNAPSHOT ISOLATION, taken as given.                                     *)
(*                                                                         *)
(* Two rules, both stated as rules rather than built out of a mechanism.    *)
(*                                                                         *)
(*   1. A transaction reads the store as it stood when the transaction      *)
(*      began, plus its own writes. `snap' is that reading.                *)
(*                                                                         *)
(*   2. First committer wins. A transaction may commit only if no           *)
(*      transaction that committed after it began wrote a key it writes.    *)
(*      `prior[t]' records who had already committed when t began, so       *)
(*      "committed after t began" is `committed and not in prior[t]'.       *)
(*                                                                         *)
(* There is no multi-version store here, no version numbers, no read        *)
(* timestamps and no garbage collection. A snapshot is a copy of a function *)
(* and a conflict is a set intersection.                                    *)
(*                                                                         *)
(* Same API as IsoSerial, so an application written against one runs        *)
(* unchanged against the other.                                             *)
(***************************************************************************)
EXTENDS Naturals, FiniteSets, TLC

CONSTANTS Key, Txn, Value

VARIABLES store,   \* committed state: [Key -> Value]
          wset,    \* per transaction pending writes, a function on a subset of Key
          state,   \* per transaction lifecycle
          snap,    \* per transaction read snapshot, taken at Begin
          prior    \* per transaction: who had committed when it began

IsoVars == <<store, wset, state, snap, prior>>

IsoTypeOK ==
  /\ store \in [Key -> Value]
  /\ state \in [Txn -> {"init", "running", "committed", "aborted"}]
  /\ snap  \in [Txn -> [Key -> Value]]
  /\ prior \in [Txn -> SUBSET Txn]
  /\ \A t \in Txn : DOMAIN wset[t] \subseteq Key

IsoInit(s0) ==
  /\ store = s0
  /\ wset  = [t \in Txn |-> << >>]
  /\ state = [t \in Txn |-> "init"]
  /\ snap  = [t \in Txn |-> s0]
  /\ prior = [t \in Txn |-> {}]

Running(t) == state[t] = "running"

Begin(t) ==
  /\ state[t] = "init"
  /\ state' = [state EXCEPT ![t] = "running"]
  /\ snap'  = [snap  EXCEPT ![t] = store]
  /\ prior' = [prior EXCEPT ![t] = {u \in Txn : state[u] = "committed"}]
  /\ UNCHANGED <<store, wset>>

\* Rule 1: the snapshot, and the transaction's own writes on top of it.
See(t, k) == IF k \in DOMAIN wset[t] THEN wset[t][k] ELSE snap[t][k]

Put(t, k, v) ==
  /\ wset' = [wset EXCEPT ![t] = (k :> v) @@ wset[t]]
  /\ UNCHANGED <<store, state, snap, prior>>

Idle == UNCHANGED IsoVars

\* Rule 2: first committer wins.
NoConflict(t) ==
  \A u \in Txn :
    (state[u] = "committed" /\ u \notin prior[t])
      => (DOMAIN wset[u] \cap DOMAIN wset[t] = {})

Finish(t) ==
  /\ IF NoConflict(t)
       THEN /\ store' = wset[t] @@ store
            /\ state' = [state EXCEPT ![t] = "committed"]
       ELSE /\ state' = [state EXCEPT ![t] = "aborted"]
            /\ UNCHANGED store
  /\ UNCHANGED <<wset, snap, prior>>

==========================================================================
