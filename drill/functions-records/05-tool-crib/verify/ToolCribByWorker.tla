------------------------- MODULE ToolCribByWorker -------------------------
(* The crib from the worker's side: each worker to the set of tools they   *)
(* hold. The limit is now a size, which is easy. "A tool is out to one     *)
(* worker" was free on the tool's side and is an obligation here.          *)
EXTENDS Naturals, FiniteSets
CONSTANTS Tools, Workers, Limit

VARIABLE holds
vars == <<holds>>

TypeOK == holds \in [Workers -> SUBSET Tools]

Out == UNION {holds[w] : w \in Workers}

Init == holds = [w \in Workers |-> {}]

SignOut(t, w) == /\ t \notin Out
                 /\ Cardinality(holds[w]) < Limit
                 /\ holds' = [holds EXCEPT ![w] = @ \cup {t}]

Return(t) == \E w \in Workers :
               /\ t \in holds[w]
               /\ holds' = [holds EXCEPT ![w] = @ \ {t}]

Next == \/ \E t \in Tools, w \in Workers : SignOut(t, w)
        \/ \E t \in Tools : Return(t)

Spec == Init /\ [][Next]_vars

WithinLimit == \A w \in Workers : Cardinality(holds[w]) <= Limit

OneHolder == \A w1, w2 \in Workers : w1 /= w2 => holds[w1] \cap holds[w2] = {}
==========================================================================
