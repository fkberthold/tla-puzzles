------------------------ MODULE AutoclavesAtDepth -------------------------
(* The path goes into the field and @ is still read as the record. At that  *)
(* depth @ is a number, and a number has no field called pressure.          *)
EXTENDS Naturals, FiniteSets
CONSTANTS Autoclaves, MaxP, Budget

VARIABLE unit
vars == <<unit>>

TypeOK == unit \in [Autoclaves -> [pressure: 0..MaxP, open: BOOLEAN]]

Pressurised == {a \in Autoclaves : unit[a].pressure > 0}

Init == unit = [a \in Autoclaves |-> [pressure |-> 0, open |-> TRUE]]

Close(a) == /\ unit[a].open
            /\ unit' = [unit EXCEPT ![a].open = FALSE]

Open(a) == /\ ~unit[a].open
           /\ unit[a].pressure = 0
           /\ unit' = [unit EXCEPT ![a].open = TRUE]

Heat(a) == /\ ~unit[a].open
           /\ unit[a].pressure < MaxP
           /\ Cardinality(Pressurised \cup {a}) <= Budget
           /\ unit' = [unit EXCEPT ![a].pressure = @.pressure + 1]

Vent(a) == /\ unit[a].pressure > 0
           /\ unit' = [unit EXCEPT ![a].pressure = @ - 1]

Next == \E a \in Autoclaves : Close(a) \/ Open(a) \/ Heat(a) \/ Vent(a)

Spec == Init /\ [][Next]_vars

DoorShutUnderPressure == \A a \in Autoclaves : unit[a].pressure > 0 => ~unit[a].open

CompressorBudget == Cardinality(Pressurised) <= Budget
==========================================================================
