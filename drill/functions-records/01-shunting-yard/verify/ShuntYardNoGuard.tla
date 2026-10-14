------------------------- MODULE ShuntYardNoGuard -------------------------
(* Both spellings right. The shunter never checks that the target track is  *)
(* free, so the yard's one rule is broken on the first move.                *)
EXTENDS Naturals
CONSTANTS Wagons, Tracks

VARIABLE pos
vars == <<pos>>

TypeOK == pos \in [Wagons -> Tracks]

NoShare == \A w1, w2 \in Wagons : w1 /= w2 => pos[w1] /= pos[w2]

Init == /\ pos \in [Wagons -> Tracks]
        /\ NoShare

Shunt(w, t) == /\ pos[w] /= t
               /\ pos' = [pos EXCEPT ![w] = t]

Next == \E w \in Wagons, t \in Tracks : Shunt(w, t)

Spec == Init /\ [][Next]_vars
==========================================================================
