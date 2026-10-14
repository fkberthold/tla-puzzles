---- MODULE PoolsNoCap ----
\* Mutant of the two-set answer. Joining a pool no longer checks for room,
\* so a third guard walks in and rule 2 reports it.
EXTENDS Naturals, FiniteSets

CONSTANTS Guards, Trainee

ASSUME Trainee \in Guards

VARIABLES lanes, leisure

vars == <<lanes, leisure>>

TypeOK ==
  /\ lanes \subseteq Guards
  /\ leisure \subseteq Guards

Init == lanes = {} /\ leisure = {}

MayLeave(pool, g) == g \in pool => pool \ {g} /= {Trainee}

MayJoin(pool, g) ==
  /\ g \notin pool
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
