---------------------------- MODULE Phases -----------------------------
(* The same station with a control variable per pump. The four labels   *)
(* follow the handbook's four steps. GoingUp and GoingDown are the same  *)
(* switch positions, told from different directions.                     *)
EXTENDS Naturals, FiniteSets
CONSTANTS Pumps, Budget,
          Offline, GoingUp, Online, GoingDown     \* labels

VARIABLES pc, inlet, motor
vars == <<pc, inlet, motor>>

Running == {p \in Pumps : motor[p]}

Init == /\ pc = [p \in Pumps |-> Offline]
        /\ inlet = [p \in Pumps |-> FALSE]
        /\ motor = [p \in Pumps |-> FALSE]

OpenInlet(p) == /\ pc[p] = Offline
                /\ pc' = [pc EXCEPT ![p] = GoingUp]
                /\ inlet' = [inlet EXCEPT ![p] = TRUE]
                /\ UNCHANGED motor

StartMotor(p) == /\ pc[p] \in {GoingUp, GoingDown}
                 /\ Cardinality(Running) < Budget
                 /\ pc' = [pc EXCEPT ![p] = Online]
                 /\ motor' = [motor EXCEPT ![p] = TRUE]
                 /\ UNCHANGED inlet

StopMotor(p) == /\ pc[p] = Online
                /\ pc' = [pc EXCEPT ![p] = GoingDown]
                /\ motor' = [motor EXCEPT ![p] = FALSE]
                /\ UNCHANGED inlet

CloseInlet(p) == /\ pc[p] \in {GoingUp, GoingDown}
                 /\ pc' = [pc EXCEPT ![p] = Offline]
                 /\ inlet' = [inlet EXCEPT ![p] = FALSE]
                 /\ UNCHANGED motor

Next == \E p \in Pumps :
          OpenInlet(p) \/ StartMotor(p) \/ StopMotor(p) \/ CloseInlet(p)

Spec == Init /\ [][Next]_vars

NeverDry == \A p \in Pumps : motor[p] => inlet[p]
WithinBudget == Cardinality(Running) <= Budget
=========================================================================
