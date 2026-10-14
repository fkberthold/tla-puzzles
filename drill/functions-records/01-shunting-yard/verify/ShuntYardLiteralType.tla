----------------------- MODULE ShuntYardLiteralType -----------------------
(* Init is right. TypeOK asks whether pos is IN a function literal, which   *)
(* is the same mistake one line lower: the invariant cannot be evaluated.   *)
EXTENDS Naturals
CONSTANTS Wagons, Tracks

VARIABLE pos
vars == <<pos>>

TypeOK == pos \in [w \in Wagons |-> Tracks]

NoShare == \A w1, w2 \in Wagons : w1 /= w2 => pos[w1] /= pos[w2]

Init == /\ pos \in [Wagons -> Tracks]
        /\ NoShare

Shunt(w, t) == /\ \A v \in Wagons : pos[v] /= t
               /\ pos' = [pos EXCEPT ![w] = t]

Next == \E w \in Wagons, t \in Tracks : Shunt(w, t)

Spec == Init /\ [][Next]_vars
==========================================================================
