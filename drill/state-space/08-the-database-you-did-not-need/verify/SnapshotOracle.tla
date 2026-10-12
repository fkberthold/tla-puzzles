-------------------------- MODULE SnapshotOracle --------------------------
EXTENDS Naturals, FiniteSets

\* THE ORACLE. Snapshot isolation stated as two rules rather than built
\* from a mechanism. Adapted from sources/spikes/isolation/IsoSnapshot.tla.
\*
\*   1. A transaction reads the store as it stood when it began, plus its
\*      own writes. `snap` is that reading.
\*   2. First committer wins. A transaction commits only if nobody who
\*      committed after it began wrote a key it writes. `prior[t]` is who
\*      had already committed when t began.
\*
\* No versions, no timestamps, no chain to scan. A snapshot is a copy of a
\* function and a conflict is a set intersection.

CONSTANTS Key, Txn, Value

VARIABLES store, wset, state, snap, prior

IsoVars == <<store, wset, state, snap, prior>>

IsoTypeOK ==
    /\ store \in [Key -> Value]
    /\ state \in [Txn -> {"init", "running", "committed", "aborted"}]
    /\ snap \in [Txn -> [Key -> Value]]
    /\ prior \in [Txn -> SUBSET Txn]
    /\ \A t \in Txn : DOMAIN wset[t] \subseteq Key

IsoInit(s0) ==
    /\ store = s0
    /\ wset = [t \in Txn |-> <<>>]
    /\ state = [t \in Txn |-> "init"]
    /\ snap = [t \in Txn |-> s0]
    /\ prior = [t \in Txn |-> {}]

Running(t) == state[t] = "running"

Begin(t) ==
    /\ state[t] = "init"
    /\ state' = [state EXCEPT ![t] = "running"]
    /\ snap' = [snap EXCEPT ![t] = store]
    /\ prior' = [prior EXCEPT ![t] = {u \in Txn : state[u] = "committed"}]
    /\ UNCHANGED <<store, wset>>

See(t, k) == IF k \in DOMAIN wset[t] THEN wset[t][k] ELSE snap[t][k]

Put(t, k, v) ==
    /\ wset' = [wset EXCEPT ![t] = [x \in DOMAIN wset[t] \cup {k} |-> IF x = k THEN v ELSE wset[t][x]]]
    /\ UNCHANGED <<store, state, snap, prior>>

Idle == UNCHANGED IsoVars

NoConflict(t) ==
    \A u \in Txn :
        (state[u] = "committed" /\ u \notin prior[t])
            => (DOMAIN wset[u] \cap DOMAIN wset[t] = {})

Finish(t) ==
    /\ IF NoConflict(t)
        THEN /\ store' = [k \in Key |-> IF k \in DOMAIN wset[t] THEN wset[t][k] ELSE store[k]]
             /\ state' = [state EXCEPT ![t] = "committed"]
        ELSE /\ state' = [state EXCEPT ![t] = "aborted"]
             /\ UNCHANGED store
    /\ UNCHANGED <<wset, snap, prior>>

===========================================================================
