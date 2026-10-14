---- MODULE PoolsSets ----
\* Reference answer, held as two sets. A guard is in lanes, in leisure, or in
\* neither, which is the break. Rule 1 is an intersection, rule 2 a count and
\* rule 3 a difference. The cost of this encoding is three actions where the
\* function encoding gets away with two.
EXTENDS Naturals, FiniteSets

CONSTANTS Guards, Trainee

ASSUME Trainee \in Guards

VARIABLES lanes, leisure

vars == <<lanes, leisure>>

TypeOK ==
  /\ lanes \subseteq Guards
  /\ leisure \subseteq Guards

Init == lanes = {} /\ leisure = {}

\* Leaving a pool is fine when it doesn't strand the trainee there.
MayLeave(pool, g) == g \in pool => pool \ {g} /= {Trainee}

\* Joining a pool needs room, and the trainee needs company.
MayJoin(pool, g) ==
  /\ g \notin pool
  /\ Cardinality(pool) < 2
  /\ g = Trainee => pool /= {}

ToLanes ==
  \E g \in Guards :
    /\ MayJoin(lanes, g)
    /\ MayLeave(leisure, g)
    /\ lanes' = lanes \cup {g}
    /\ leisure' = leisure \ {g}

ToLeisure ==
  \E g \in Guards :
    /\ MayJoin(leisure, g)
    /\ MayLeave(lanes, g)
    /\ leisure' = leisure \cup {g}
    /\ lanes' = lanes \ {g}

ToBreak ==
  \E g \in lanes \cup leisure :
    /\ MayLeave(lanes, g)
    /\ MayLeave(leisure, g)
    /\ lanes' = lanes \ {g}
    /\ leisure' = leisure \ {g}

Next == ToLanes \/ ToLeisure \/ ToBreak

Spec == Init /\ [][Next]_vars

NobodyAtBoth == lanes \cap leisure = {}

AtMostTwo == Cardinality(lanes) <= 2 /\ Cardinality(leisure) <= 2

TraineeNeverAlone == lanes /= {Trainee} /\ leisure /= {Trainee}
====
