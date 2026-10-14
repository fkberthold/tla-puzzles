--------------------------- MODULE HoistUnguarded ---------------------------
\* The other wrong neighbor: the sum is right and nothing consults it
\* before a crate boards.
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
    /\ aboard' = aboard \cup {c}

Unload(c) ==
    /\ c \in aboard
    /\ aboard' = aboard \ {c}

Next == \E c \in Crates : Board(c) \/ Unload(c)

Spec == Init /\ [][Next]_aboard

Safe == Load <= Limit

=============================================================================
