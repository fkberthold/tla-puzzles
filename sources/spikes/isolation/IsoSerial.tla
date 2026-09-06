---------------------------- MODULE IsoSerial ----------------------------
(***************************************************************************)
(* SERIALISABLE, taken as given.                                           *)
(*                                                                         *)
(* This is scaffolding, not a specification of a database. It says what a   *)
(* transaction is allowed to observe and when its writes take effect, and   *)
(* nothing about how any engine arranges that. There are no versions, no    *)
(* timestamps, no locks and no log.                                         *)
(*                                                                         *)
(* The rule: transactions take effect one at a time. `current' holds the    *)
(* at most one transaction that is allowed to run, so no second            *)
(* transaction can start until the first has finished.                     *)
(*                                                                         *)
(* Modelling serialisable as SERIAL is a restriction, and it is a sound     *)
(* one for checking an application invariant. Every serialisable execution  *)
(* leaves the committed store where some serial execution leaves it, so an  *)
(* invariant that holds over all serial orders holds over all serialisable  *)
(* executions. It is not sound for liveness, and it says nothing about      *)
(* throughput.                                                             *)
(*                                                                         *)
(* The API an application is written against, shared by all three levels:   *)
(*                                                                         *)
(*   IsoInit(s0)   initialise the store to s0                              *)
(*   IsoVars       the tuple of scaffolding variables                      *)
(*   Begin(t)      action: t starts                                        *)
(*   Running(t)    predicate: t may take an application step               *)
(*   See(t, k)     state function: the value t observes for key k          *)
(*   Put(t, k, v)  action: t writes v to k                                 *)
(*   Idle          action: t looks and writes nothing                      *)
(*   Finish(t)     action: t attempts to commit                            *)
(***************************************************************************)
EXTENDS Naturals, FiniteSets, TLC

CONSTANTS Key, Txn, Value

VARIABLES store,    \* committed state: [Key -> Value]
          wset,     \* per transaction pending writes, a function on a subset of Key
          state,    \* per transaction lifecycle
          current   \* the at most one transaction allowed to run

IsoVars == <<store, wset, state, current>>

IsoTypeOK ==
  /\ store \in [Key -> Value]
  /\ state \in [Txn -> {"init", "running", "committed", "aborted"}]
  /\ current \subseteq Txn
  /\ \A t \in Txn : DOMAIN wset[t] \subseteq Key

IsoInit(s0) ==
  /\ store   = s0
  /\ wset    = [t \in Txn |-> << >>]
  /\ state   = [t \in Txn |-> "init"]
  /\ current = {}

Running(t) == /\ state[t] = "running"
              /\ current = {t}

Begin(t) ==
  /\ state[t] = "init"
  /\ current = {}
  /\ state'   = [state EXCEPT ![t] = "running"]
  /\ current' = {t}
  /\ UNCHANGED <<store, wset>>

\* A running transaction reads the committed store, and its own writes first.
See(t, k) == IF k \in DOMAIN wset[t] THEN wset[t][k] ELSE store[k]

Put(t, k, v) ==
  /\ wset' = [wset EXCEPT ![t] = (k :> v) @@ wset[t]]
  /\ UNCHANGED <<store, state, current>>

Idle == UNCHANGED IsoVars

\* Under serial execution nothing can have conflicted, so commit never fails.
Finish(t) ==
  /\ store'   = wset[t] @@ store
  /\ state'   = [state EXCEPT ![t] = "committed"]
  /\ current' = {}
  /\ UNCHANGED wset

==========================================================================
