---- MODULE PoolsPairs ----
\* Accepted variant, held as a set of pairs: who is at which pool. A guard
\* on a break has no pair. Rule 1 says no guard appears in two pairs, which
\* the two-set encoding said with an intersection.
EXTENDS Naturals, FiniteSets

CONSTANTS Guards, Trainee

ASSUME Trainee \in Guards

Pools == {"lanes", "leisure"}

VARIABLE at

vars == <<at>>

TypeOK == at \subseteq Guards \X Pools

Crew(p) == {g \in Guards : <<g, p>> \in at}

Init == at = {}

MayLeave(p, g) == g \in Crew(p) => Crew(p) \ {g} /= {Trainee}

MayJoin(p, g) ==
  /\ g \notin Crew(p)
  /\ Cardinality(Crew(p)) < 2
  /\ g = Trainee => Crew(p) /= {}

Move ==
  \E g \in Guards, p \in Pools :
    /\ MayJoin(p, g)
    /\ \A q \in Pools : MayLeave(q, g)
    /\ at' = {x \in at : x[1] /= g} \cup {<<g, p>>}

ToBreak ==
  \E x \in at :
    /\ MayLeave(x[2], x[1])
    /\ at' = at \ {x}

Next == Move \/ ToBreak

Spec == Init /\ [][Next]_vars

NobodyAtBoth == \A x, y \in at : x[1] = y[1] => x = y

AtMostTwo == \A p \in Pools : Cardinality(Crew(p)) <= 2

TraineeNeverAlone == \A p \in Pools : Crew(p) /= {Trainee}
====
