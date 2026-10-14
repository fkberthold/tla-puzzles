------------------------- MODULE ToolCribEmptyTuple -----------------------
(* Variant: the empty function written as the empty tuple. A tuple is a    *)
(* function on 1..n, so the empty tuple is the function with no domain,    *)
(* which is the same value the constructor over the empty set builds.      *)
EXTENDS Naturals, FiniteSets, TLC
CONSTANTS Tools, Workers, Limit

VARIABLE out
vars == <<out>>

TypeOK == /\ DOMAIN out \subseteq Tools
          /\ \A t \in DOMAIN out : out[t] \in Workers

Holding(w) == {t \in DOMAIN out : out[t] = w}

Init == out = <<>>

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
