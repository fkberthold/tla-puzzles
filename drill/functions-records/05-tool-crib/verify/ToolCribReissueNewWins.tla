---------------------- MODULE ToolCribReissueNewWins ----------------------
(* The same missing guard with the merge the other way round. Now the new  *)
(* key wins, so a tool that is out moves to the new worker without ever    *)
(* coming back. Still no error, and still the reference's states, because  *)
(* every state it reaches was reachable by a return and a fresh sign-out.  *)
EXTENDS Naturals, FiniteSets, TLC
CONSTANTS Tools, Workers, Limit

VARIABLE out
vars == <<out>>

TypeOK == /\ DOMAIN out \subseteq Tools
          /\ \A t \in DOMAIN out : out[t] \in Workers

Holding(w) == {t \in DOMAIN out : out[t] = w}

Init == out = [t \in {} |-> 0]

SignOut(t, w) == /\ Cardinality(Holding(w)) < Limit
                 /\ out' = (t :> w) @@ out

Return(t) == /\ t \in DOMAIN out
             /\ out' = [u \in (DOMAIN out) \ {t} |-> out[u]]

Next == \/ \E t \in Tools, w \in Workers : SignOut(t, w)
        \/ \E t \in Tools : Return(t)

Spec == Init /\ [][Next]_vars

WithinLimit == \A w \in Workers : Cardinality(Holding(w)) <= Limit
==========================================================================
