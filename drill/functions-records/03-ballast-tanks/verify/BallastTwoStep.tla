-------------------------- MODULE BallastTwoStep --------------------------
(* The programmer's pump: draw a unit out of one tank, then on a later     *)
(* step put it into another. Between the two steps the gauges read 5.      *)
EXTENDS Naturals
CONSTANTS Fore, Port, Stbd, Cap

Tanks == {Fore, Port, Stbd}

VARIABLES level, hose
vars == <<level, hose>>

TypeOK == /\ level \in [Tanks -> 0..Cap]
          /\ hose \in 0..1

Aboard == level[Fore] + level[Port] + level[Stbd]

Init == /\ level = [t \in Tanks |-> 2]
        /\ hose = 0

Draw(a) == /\ hose = 0
           /\ level[a] > 0
           /\ level' = [level EXCEPT ![a] = @ - 1]
           /\ hose' = 1

Fill(b) == /\ hose = 1
           /\ level[b] < Cap
           /\ level' = [level EXCEPT ![b] = @ + 1]
           /\ hose' = 0

Next == \E t \in Tanks : Draw(t) \/ Fill(t)

Spec == Init /\ [][Next]_vars

Conserved == Aboard = 6
==========================================================================
