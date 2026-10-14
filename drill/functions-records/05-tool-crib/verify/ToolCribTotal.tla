--------------------------- MODULE ToolCribTotal --------------------------
(* The same crib as a total function with a hole value. Every tool always  *)
(* has an entry, InCrib when it is on the shelf, so the domain never moves *)
(* and every update is an ordinary in-place one. Same information, same   *)
(* states.                                                                  *)
EXTENDS Naturals, FiniteSets
CONSTANTS Tools, Workers, Limit, InCrib

VARIABLE out
vars == <<out>>

TypeOK == out \in [Tools -> Workers \cup {InCrib}]

Holding(w) == {t \in Tools : out[t] = w}

Init == out = [t \in Tools |-> InCrib]

SignOut(t, w) == /\ out[t] = InCrib
                 /\ Cardinality(Holding(w)) < Limit
                 /\ out' = [out EXCEPT ![t] = w]

Return(t) == /\ out[t] /= InCrib
             /\ out' = [out EXCEPT ![t] = InCrib]

Next == \/ \E t \in Tools, w \in Workers : SignOut(t, w)
        \/ \E t \in Tools : Return(t)

Spec == Init /\ [][Next]_vars

WithinLimit == \A w \in Workers : Cardinality(Holding(w)) <= Limit
==========================================================================
