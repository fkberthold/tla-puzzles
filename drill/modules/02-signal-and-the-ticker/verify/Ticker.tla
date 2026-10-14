------------------------------ MODULE Ticker ------------------------------
\* The fine machine. A counter from 0 to 5 that wraps, and a reading of it
\* as a colour. The reading is the refinement mapping.
EXTENDS Naturals

VARIABLE tick

Init == tick = 0

Next == tick' = (tick + 1) % 6

Spec == Init /\ [][Next]_tick

Shown ==
    IF tick < 3 THEN "red"
    ELSE IF tick < 5 THEN "green"
    ELSE "amber"

S == INSTANCE Signal WITH colour <- Shown

Refinement == S!Spec

=============================================================================
