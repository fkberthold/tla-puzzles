------------------------------ MODULE HoistFn ------------------------------
\* A variant: the sum as a recursive function over subsets, which needs no
\* declaration because a function may refer to itself by name.
EXTENDS Naturals

CONSTANTS Crates, Limit

VARIABLE aboard

Load ==
    LET Sum[S \in SUBSET Crates] ==
            IF S = {} THEN 0
            ELSE LET c == CHOOSE c \in S : TRUE IN c + Sum[S \ {c}]
    IN  Sum[aboard]

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
