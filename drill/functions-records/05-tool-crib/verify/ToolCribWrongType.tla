------------------------- MODULE ToolCribWrongType ------------------------
(* TypeOK written as if out were total. The function set [Tools -> Workers] *)
(* holds only functions whose domain is all of Tools, and the empty         *)
(* function is not one of them, so the first state fails.                   *)
EXTENDS Naturals, FiniteSets, TLC
CONSTANTS Tools, Workers, Limit

VARIABLE out
vars == <<out>>

TypeOK == out \in [Tools -> Workers]

Holding(w) == {t \in DOMAIN out : out[t] = w}

Init == out = [t \in {} |-> 0]

SignOut(t, w) == /\ t \notin DOMAIN out
                 /\ Cardinality(Holding(w)) < Limit
                 /\ out' = out @@ (t :> w)

Return(t) == /\ t \in DOMAIN out
             /\ out' = [u \in (DOMAIN out) \ {t} |-> out[u]]

Next == \/ \E t \in Tools, w \in Workers : SignOut(t, w)
        \/ \E t \in Tools : Return(t)

Spec == Init /\ [][Next]_vars

WithinLimit == \A w \in Workers : Cardinality(Holding(w)) <= Limit
==========================================================================
