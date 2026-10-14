---------------------------- MODULE BaysVanSide ---------------------------
(* Encoding C: the van's side. at says which bay each van is in, or Away,  *)
(* and plugged is per van. Now "a van is in one bay" is free and "a bay     *)
(* holds one van" is the obligation. The mirror image of BaysTwoFns.        *)
CONSTANTS Bays, Vans, Away

VARIABLES at, plugged
vars == <<at, plugged>>

TypeOK == /\ at \in [Vans -> Bays \cup {Away}]
          /\ plugged \in [Vans -> BOOLEAN]

Occupied(b) == \E v \in Vans : at[v] = b

Init == /\ at = [v \in Vans |-> Away]
        /\ plugged = [v \in Vans |-> FALSE]

DriveIn(v, b) == /\ at[v] = Away
                 /\ ~Occupied(b)
                 /\ at' = [at EXCEPT ![v] = b]
                 /\ UNCHANGED plugged

DriveOut(v) == /\ at[v] /= Away
               /\ ~plugged[v]
               /\ at' = [at EXCEPT ![v] = Away]
               /\ UNCHANGED plugged

PlugIn(v) == /\ at[v] /= Away
             /\ ~plugged[v]
             /\ plugged' = [plugged EXCEPT ![v] = TRUE]
             /\ UNCHANGED at

Unplug(v) == /\ plugged[v]
             /\ plugged' = [plugged EXCEPT ![v] = FALSE]
             /\ UNCHANGED at

Next == \E v \in Vans :
          \/ \E b \in Bays : DriveIn(v, b)
          \/ DriveOut(v) \/ PlugIn(v) \/ Unplug(v)

Spec == Init /\ [][Next]_vars

NeverPlugEmpty == \A v \in Vans : plugged[v] => at[v] /= Away

OneVanPerBay == \A v1, v2 \in Vans :
                  (v1 /= v2 /\ at[v1] /= Away) => at[v1] /= at[v2]
==========================================================================
