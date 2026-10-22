---- MODULE Split ----
EXTENDS Integers
VARIABLES a, b
vars == <<a, b>>

T == INSTANCE Tally WITH total <- a + b

Init == a = 0 /\ b = 0
BumpA == a' = a + 1 /\ b' = b
BumpB == b' = b + 1 /\ a' = a
Next == BumpA \/ BumpB
Spec == Init /\ [][Next]_vars

Cap == a <= 2 /\ b <= 2

Tree == [][T!Bump <=> (a' + b' = a + b + 1)]_vars
Text == [][T!Bump <=> (a + b' = a + b + 1)]_vars
======================
