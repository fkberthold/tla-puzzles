--------------------------- MODULE TickerNoAmber ---------------------------
\* The wrong mapping: tick 5 reads as green, so the wrap from 5 to 0 maps
\* to a green-to-red step, which the coarse machine never takes.
EXTENDS Naturals

VARIABLE tick

Init == tick = 0

Next == tick' = (tick + 1) % 6

Spec == Init /\ [][Next]_tick

Shown == IF tick < 3 THEN "red" ELSE "green"

S == INSTANCE Signal WITH colour <- Shown

Refinement == S!Spec

=============================================================================
