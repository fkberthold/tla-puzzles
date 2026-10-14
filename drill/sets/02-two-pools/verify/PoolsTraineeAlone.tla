---- MODULE PoolsTraineeAlone ----
\* Mutant of the two-set answer. Nothing stops the trainee joining an empty
\* pool or the last senior leaving one, so rule 3 reports it.
EXTENDS Naturals, FiniteSets

CONSTANTS Guards, Trainee

ASSUME Trainee \in Guards

VARIABLES lanes, leisure

vars == <<lanes, leisure>>

TypeOK ==
  /\ lanes \subseteq Guards
  /\ leisure \subseteq Guards

Init == lanes = {} /\ leisure = {}

MayJoin(pool, g) ==
  /\ g \notin pool
  /\ Cardinality(pool) < 2

ToLanes ==
  \E g \in Guards :
    /\ MayJoin(lanes, g)
    /\ lanes' = lanes \cup {g}
    /\ leisure' = leisure \ {g}

ToLeisure ==
  \E g \in Guards :
    /\ MayJoin(leisure, g)
    /\ leisure' = leisure \cup {g}
    /\ lanes' = lanes \ {g}

ToBreak ==
  \E g \in lanes \cup leisure :
    /\ lanes' = lanes \ {g}
    /\ leisure' = leisure \ {g}

Next == ToLanes \/ ToLeisure \/ ToBreak

Spec == Init /\ [][Next]_vars

NobodyAtBoth == lanes \cap leisure = {}

AtMostTwo == Cardinality(lanes) <= 2 /\ Cardinality(leisure) <= 2

TraineeNeverAlone == lanes /= {Trainee} /\ leisure /= {Trainee}
====
