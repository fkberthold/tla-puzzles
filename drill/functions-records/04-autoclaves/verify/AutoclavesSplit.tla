-------------------------- MODULE AutoclavesSplit -------------------------
(* The same lab as two functions, one per field. Nothing wrong with it.    *)
(* Every single-field update now has to say the other function is held.   *)
EXTENDS Naturals, FiniteSets
CONSTANTS Autoclaves, MaxP, Budget

VARIABLES pressure, open
vars == <<pressure, open>>

TypeOK == /\ pressure \in [Autoclaves -> 0..MaxP]
          /\ open \in [Autoclaves -> BOOLEAN]

Pressurised == {a \in Autoclaves : pressure[a] > 0}

Init == /\ pressure = [a \in Autoclaves |-> 0]
        /\ open = [a \in Autoclaves |-> TRUE]

Close(a) == /\ open[a]
            /\ open' = [open EXCEPT ![a] = FALSE]
            /\ UNCHANGED pressure

Open(a) == /\ ~open[a]
           /\ pressure[a] = 0
           /\ open' = [open EXCEPT ![a] = TRUE]
           /\ UNCHANGED pressure

Heat(a) == /\ ~open[a]
           /\ pressure[a] < MaxP
           /\ Cardinality(Pressurised \cup {a}) <= Budget
           /\ pressure' = [pressure EXCEPT ![a] = @ + 1]
           /\ UNCHANGED open

Vent(a) == /\ pressure[a] > 0
           /\ pressure' = [pressure EXCEPT ![a] = @ - 1]
           /\ UNCHANGED open

Next == \E a \in Autoclaves : Close(a) \/ Open(a) \/ Heat(a) \/ Vent(a)

Spec == Init /\ [][Next]_vars

DoorShutUnderPressure == \A a \in Autoclaves : pressure[a] > 0 => ~open[a]

CompressorBudget == Cardinality(Pressurised) <= Budget
==========================================================================
