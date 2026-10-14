----------------------------- MODULE ToolCrib -----------------------------
(* The reference. out is a partial function: its domain is exactly the     *)
(* tools that are out, and it grows and shrinks. Signing out adds one key  *)
(* by merging a one-key function in; returning rebuilds the function over  *)
(* the domain less that key, because nothing removes a key in place.       *)
EXTENDS Naturals, FiniteSets, TLC
CONSTANTS Tools, Workers, Limit

VARIABLE out
vars == <<out>>

TypeOK == /\ DOMAIN out \subseteq Tools
          /\ \A t \in DOMAIN out : out[t] \in Workers

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
