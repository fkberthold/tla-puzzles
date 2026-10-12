------------------------------- MODULE MVCC -------------------------------
EXTENDS Naturals, FiniteSets, Sequences

\* THE MECHANISM. A multi-version store with a global timestamp counter,
\* per-transaction start timestamps, version chains per key and
\* first-committer-wins conflict detection by scanning the chain. This is
\* a cut-down version of how a snapshot-isolation engine is built, and it
\* is here to be measured against the oracle in SnapshotOracle.tla.
\*
\* The application is the same rostering service as OnCallOracle.tla:
\* every doctor is also the one transaction that doctor runs, and a doctor
\* goes off call only after seeing at least two on call.

CONSTANT Doctor

VARIABLES ts, versions, startTs, wset, state, pc

vars == <<ts, versions, startTs, wset, state, pc>>

Version == [val: {"on", "off"}, cts: Nat]

TypeOK ==
    /\ ts \in Nat
    /\ versions \in [Doctor -> Seq(Version)]
    /\ startTs \in [Doctor -> Nat]
    /\ wset \in [Doctor -> SUBSET Doctor]
    /\ state \in [Doctor -> {"init", "running", "committed", "aborted"}]
    /\ pc \in [Doctor -> {"begin", "check", "finish", "done"}]

Init ==
    /\ ts = 0
    /\ versions = [d \in Doctor |-> <<[val |-> "on", cts |-> 0]>>]
    /\ startTs = [d \in Doctor |-> 0]
    /\ wset = [d \in Doctor |-> {}]
    /\ state = [d \in Doctor |-> "init"]
    /\ pc = [d \in Doctor |-> "begin"]

\* The newest version of d committed at or before t started.
Visible(t, d) ==
    LET vs == versions[d]
        ok == {i \in 1..Len(vs) : vs[i].cts <= startTs[t]}
        last == CHOOSE i \in ok : \A j \in ok : j <= i
    IN vs[last].val

See(t, d) == IF d \in wset[t] THEN "off" ELSE Visible(t, d)

Begin(t) ==
    /\ pc[t] = "begin"
    /\ ts' = ts + 1
    /\ startTs' = [startTs EXCEPT ![t] = ts + 1]
    /\ state' = [state EXCEPT ![t] = "running"]
    /\ pc' = [pc EXCEPT ![t] = "check"]
    /\ UNCHANGED <<versions, wset>>

SeenOnCall(t) == Cardinality({d \in Doctor : See(t, d) = "on"})

Check(t) ==
    /\ pc[t] = "check"
    /\ wset' = [wset EXCEPT ![t] = IF SeenOnCall(t) >= 2 THEN {t} ELSE {}]
    /\ pc' = [pc EXCEPT ![t] = "finish"]
    /\ UNCHANGED <<ts, versions, startTs, state>>

\* First committer wins: a conflict is a version of a key t writes whose
\* commit timestamp is later than t's start.
Conflict(t) ==
    \E d \in wset[t] : \E i \in 1..Len(versions[d]) : versions[d][i].cts > startTs[t]

Commit(t) ==
    /\ pc[t] = "finish"
    /\ ~Conflict(t)
    /\ ts' = ts + 1
    /\ versions' = [d \in Doctor |->
                        IF d \in wset[t]
                        THEN Append(versions[d], [val |-> "off", cts |-> ts + 1])
                        ELSE versions[d]]
    /\ state' = [state EXCEPT ![t] = "committed"]
    /\ pc' = [pc EXCEPT ![t] = "done"]
    /\ UNCHANGED <<startTs, wset>>

Abort(t) ==
    /\ pc[t] = "finish"
    /\ Conflict(t)
    /\ state' = [state EXCEPT ![t] = "aborted"]
    /\ pc' = [pc EXCEPT ![t] = "done"]
    /\ UNCHANGED <<ts, versions, startTs, wset>>

Next == \E t \in Doctor : Begin(t) \/ Check(t) \/ Commit(t) \/ Abort(t)

Spec == Init /\ [][Next]_vars

Latest(d) == versions[d][Len(versions[d])].val
OnCall == {d \in Doctor : Latest(d) = "on"}

AtLeastOneOnCall == OnCall # {}

===========================================================================
