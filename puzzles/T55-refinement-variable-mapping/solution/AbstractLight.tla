---- MODULE AbstractLight ----

VARIABLE lampOn

vars == << lampOn >>

Init == lampOn = FALSE
Toggle == lampOn' = ~lampOn
Next == Toggle
Spec == Init /\ [][Next]_vars

====
