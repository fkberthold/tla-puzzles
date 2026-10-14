------------------------------- MODULE Hoist -------------------------------
\* A goods hoist. Crates are told apart by weight, and the load is the sum
\* of what is aboard. Summing a set needs a recursive operator, and the
\* operator lives inside the definition that uses it.
EXTENDS Naturals

CONSTANTS Crates, Limit

VARIABLE aboard

Load ==
    LET Pick(S) == CHOOSE c \in S : TRUE
        RECURSIVE Sum(_)
        Sum(S) == IF S = {} THEN 0 ELSE Pick(S) + Sum(S \ {Pick(S)})
    IN  Sum(aboard)

Init == aboard = {}

Board(c) ==
    /\ c \in Crates \ aboard
    /\ Load + c <= Limit
    /\ aboard' = aboard \cup {c}

Unload(c) ==
    /\ c \in aboard
    /\ aboard' = aboard \ {c}

Next == \E c \in Crates : Board(c) \/ Unload(c)

Spec == Init /\ [][Next]_aboard

Safe == Load <= Limit

=============================================================================
