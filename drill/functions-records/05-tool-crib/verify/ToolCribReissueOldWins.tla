---------------------- MODULE ToolCribReissueOldWins ----------------------
(* SignOut no longer checks that the tool is in. The merge keeps the LEFT  *)
(* value on a shared key, and out is on the left, so signing out a tool    *)
(* that is already out changes nothing. A silent no-op: no error, and the  *)
(* same states as the reference.                                            *)
EXTENDS Naturals, FiniteSets, TLC
CONSTANTS Tools, Workers, Limit

VARIABLE out
vars == <<out>>

TypeOK == /\ DOMAIN out \subseteq Tools
          /\ \A t \in DOMAIN out : out[t] \in Workers

Holding(w) == {t \in DOMAIN out : out[t] = w}

Init == out = [t \in {} |-> 0]

SignOut(t, w) == /\ Cardinality(Holding(w)) < Limit
                 /\ out' = out @@ (t :> w)

Return(t) == /\ t \in DOMAIN out
             /\ out' = [u \in (DOMAIN out) \ {t} |-> out[u]]

Next == \/ \E t \in Tools, w \in Workers : SignOut(t, w)
        \/ \E t \in Tools : Return(t)

Spec == Init /\ [][Next]_vars

WithinLimit == \A w \in Workers : Cardinality(Holding(w)) <= Limit
==========================================================================
