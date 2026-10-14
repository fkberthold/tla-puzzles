--------------------------- MODULE TickerTheorem ---------------------------
\* The same wrong mapping as TickerNoAmber, stated as a theorem instead of
\* a checked property. TLC does not check theorems.
EXTENDS Naturals

VARIABLE tick

Init == tick = 0

Next == tick' = (tick + 1) % 6

Spec == Init /\ [][Next]_tick

Shown == IF tick < 3 THEN "red" ELSE "green"

S == INSTANCE Signal WITH color <- Shown

THEOREM Spec => S!Spec

=============================================================================
