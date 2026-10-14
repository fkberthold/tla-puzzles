------------------------- MODULE ShuntYardSetInit -------------------------
(* Init says pos EQUALS the function set, so pos is a set of 64          *)
(* functions rather than a function. TypeOK then asks whether a SET is   *)
(* in a set of functions, and TLC refuses that rather than answering.    *)
(* The run stops at rc 75, unable to fingerprint, and names the TypeOK   *)
(* line. So the reader gets no invariant name and no trace.              *)
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
