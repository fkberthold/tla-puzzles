---- MODULE PoolsCrew ----
\* Accepted variant, held as a function from pool to the set of guards at
\* it. One Move covers both pools, which the two-set encoding can't do, and
\* the set of guards in the water is a flattening over the pools.
EXTENDS Naturals, FiniteSets

CONSTANTS Guards, Trainee

ASSUME Trainee \in Guards

Pools == {"lanes", "leisure"}

VARIABLE crew

vars == <<crew>>

TypeOK == crew \in [Pools -> SUBSET Guards]

InWater == UNION {crew[p] : p \in Pools}

Init == crew = [p \in Pools |-> {}]

MayLeave(p, g) == g \in crew[p] => crew[p] \ {g} /= {Trainee}

MayJoin(p, g) ==
  /\ g \notin crew[p]
  /\ Cardinality(crew[p]) < 2
  /\ g = Trainee => crew[p] /= {}

Move ==
  \E g \in Guards, p \in Pools :
    /\ MayJoin(p, g)
    /\ \A q \in Pools : MayLeave(q, g)
    /\ crew' = [q \in Pools |-> IF q = p THEN crew[q] \cup {g} ELSE crew[q] \ {g}]

ToBreak ==
  \E g \in InWater :
    /\ \A q \in Pools : MayLeave(q, g)
    /\ crew' = [q \in Pools |-> crew[q] \ {g}]

Next == Move \/ ToBreak

Spec == Init /\ [][Next]_vars

NobodyAtBoth == \A p, q \in Pools : p /= q => crew[p] \cap crew[q] = {}

AtMostTwo == \A p \in Pools : Cardinality(crew[p]) <= 2

TraineeNeverAlone == \A p \in Pools : crew[p] /= {Trainee}
====
