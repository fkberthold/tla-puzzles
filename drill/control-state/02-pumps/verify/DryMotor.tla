---------------------------- MODULE DryMotor ------------------------
(* Switches.tla with the handbook's "stop the motor, then close the      *)
(* inlet" dropped: CloseInlet no longer checks the motor.                *)
EXTENDS Naturals, FiniteSets
CONSTANTS Pumps, Budget

VARIABLES inlet, motor
vars == <<inlet, motor>>

Running == {p \in Pumps : motor[p]}

Init == /\ inlet = [p \in Pumps |-> FALSE]
        /\ motor = [p \in Pumps |-> FALSE]

OpenInlet(p) == /\ ~inlet[p]
                /\ inlet' = [inlet EXCEPT ![p] = TRUE]
                /\ UNCHANGED motor

StartMotor(p) == /\ inlet[p]
                 /\ ~motor[p]
                 /\ Cardinality(Running) < Budget
                 /\ motor' = [motor EXCEPT ![p] = TRUE]
                 /\ UNCHANGED inlet

StopMotor(p) == /\ motor[p]
                /\ motor' = [motor EXCEPT ![p] = FALSE]
                /\ UNCHANGED inlet

CloseInlet(p) == /\ inlet[p]                         \* no ~motor[p]
                 /\ inlet' = [inlet EXCEPT ![p] = FALSE]
                 /\ UNCHANGED motor

Next == \E p \in Pumps :
          OpenInlet(p) \/ StartMotor(p) \/ StopMotor(p) \/ CloseInlet(p)

Spec == Init /\ [][Next]_vars

NeverDry == \A p \in Pumps : motor[p] => inlet[p]
WithinBudget == Cardinality(Running) <= Budget
=========================================================================
