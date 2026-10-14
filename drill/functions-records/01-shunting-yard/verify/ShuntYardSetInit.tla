------------------------- MODULE ShuntYardSetInit -------------------------
(* Init says pos EQUALS the function set. pos is then a set of 64         *)
(* functions, not a function. TypeOK, which asks whether pos is IN that    *)
(* set, is false on the first state.                                       *)
EXTENDS Naturals
CONSTANTS Wagons, Tracks

VARIABLE pos
vars == <<pos>>

TypeOK == pos \in [Wagons -> Tracks]

NoShare == \A w1, w2 \in Wagons : w1 /= w2 => pos[w1] /= pos[w2]

Init == pos = [Wagons -> Tracks]

Shunt(w, t) == /\ \A v \in Wagons : pos[v] /= t
               /\ pos' = [pos EXCEPT ![w] = t]

Next == \E w \in Wagons, t \in Tracks : Shunt(w, t)

Spec == Init /\ [][Next]_vars
==========================================================================
