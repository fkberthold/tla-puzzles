---------------------------- MODULE ShuntYard ----------------------------
(* The reference. pos is one function, wagon to track. Init draws it from   *)
(* the set of all such functions and keeps the ones the rule allows; TypeOK *)
(* names the same set. The two spellings of "function" are both here, each  *)
(* in the one place it belongs.                                             *)
EXTENDS Naturals
CONSTANTS Wagons, Tracks

VARIABLE pos
vars == <<pos>>

TypeOK == pos \in [Wagons -> Tracks]

NoShare == \A w1, w2 \in Wagons : w1 /= w2 => pos[w1] /= pos[w2]

Init == /\ pos \in [Wagons -> Tracks]
        /\ NoShare

Shunt(w, t) == /\ \A v \in Wagons : pos[v] /= t
               /\ pos' = [pos EXCEPT ![w] = t]

Next == \E w \in Wagons, t \in Tracks : Shunt(w, t)

Spec == Init /\ [][Next]_vars
==========================================================================
