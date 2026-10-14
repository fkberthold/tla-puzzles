--------------------------- MODULE TickerNoWith ---------------------------
\* The missing mapping: the instance names no substitution for colour and
\* this module declares no variable of that name to pass through.
EXTENDS Naturals

VARIABLE tick

Init == tick = 0

Next == tick' = (tick + 1) % 6

Spec == Init /\ [][Next]_tick

S == INSTANCE Signal

Refinement == S!Spec

=============================================================================
