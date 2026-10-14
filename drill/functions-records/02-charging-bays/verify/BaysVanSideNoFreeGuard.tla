----------------------- MODULE BaysVanSideNoFreeGuard ---------------------
(* Encoding C with ITS obligation left unguarded: DriveIn never asks        *)
(* whether the bay is free, so two vans end up in one bay. The mirror of   *)
(* BaysTwoFnsNoParkedGuard: each side forgets the thing it does not get   *)
(* for free.                                                                *)
CONSTANTS Bays, Vans, Away

VARIABLES at, plugged
vars == <<at, plugged>>

TypeOK == /\ at \in [Vans -> Bays \cup {Away}]
          /\ plugged \in [Vans -> BOOLEAN]

Init == /\ at = [v \in Vans |-> Away]
        /\ plugged = [v \in Vans |-> FALSE]

DriveIn(v, b) == /\ at[v] = Away
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
