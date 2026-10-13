---- MODULE Quorums ----
EXTENDS Naturals, FiniteSets

CONSTANT Proc

Ballot == {"yes", "no"}

Quorum ==
  {q \in SUBSET Proc : 2 * Cardinality(q) > Cardinality(Proc)}

VARIABLES vote, outcomes
vars == <<vote, outcomes>>

TypeOK ==
  /\ vote \in [Proc -> Ballot \cup {"-"}]
  /\ outcomes \subseteq Ballot

Init ==
  /\ vote = [p \in Proc |-> "-"]
  /\ outcomes = {}

Cast(p, v) ==
  /\ vote[p] = "-"
  /\ vote' = [vote EXCEPT ![p] = v]
  /\ UNCHANGED outcomes

Decide(v) ==
  /\ \E q \in Quorum : \A p \in q : vote[p] = v
  /\ outcomes' = outcomes \cup {v}
  /\ UNCHANGED vote

Next ==
  \/ \E p \in Proc, v \in Ballot : Cast(p, v)
  \/ \E v \in Ballot : Decide(v)

Spec == Init /\ [][Next]_vars

Agreement == Cardinality(outcomes) <= 1

Justified ==
  \A v \in outcomes :
    \E q \in Quorum : \A p \in q : vote[p] = v

Settled == [][outcomes \subseteq outcomes']_vars
====
