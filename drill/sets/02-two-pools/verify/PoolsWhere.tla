---- MODULE PoolsWhere ----
\* Accepted variant, held as a function from guard to place. Rule 1 holds by
\* construction, since a function gives one value per guard. It's stated
\* anyway so the config carries all three names.
EXTENDS Naturals, FiniteSets

CONSTANTS Guards, Trainee

ASSUME Trainee \in Guards

Pools == {"lanes", "leisure"}
Places == Pools \cup {"break"}

VARIABLE where

vars == <<where>>

TypeOK == where \in [Guards -> Places]

Crew(p) == {g \in Guards : where[g] = p}

Init == where = [g \in Guards |-> "break"]

MayLeave(g) == where[g] \in Pools => Crew(where[g]) \ {g} /= {Trainee}

MayJoin(p, g) ==
  /\ Cardinality(Crew(p)) < 2
  /\ g = Trainee => Crew(p) /= {}

Move ==
  \E g \in Guards, p \in Places :
    /\ p /= where[g]
    /\ MayLeave(g)
    /\ p \in Pools => MayJoin(p, g)
    /\ where' = [where EXCEPT ![g] = p]

Next == Move

Spec == Init /\ [][Next]_vars

NobodyAtBoth == \A g \in Guards : Cardinality({p \in Pools : where[g] = p}) <= 1

AtMostTwo == \A p \in Pools : Cardinality(Crew(p)) <= 2

TraineeNeverAlone == \A p \in Pools : Crew(p) /= {Trainee}
====
