------------------------------ MODULE Signal ------------------------------
\* The coarse machine. Three colours in a fixed cycle, nothing else.
VARIABLE colour

Init == colour = "red"

Next ==
    \/ colour = "red"   /\ colour' = "green"
    \/ colour = "green" /\ colour' = "amber"
    \/ colour = "amber" /\ colour' = "red"

Spec == Init /\ [][Next]_colour

=============================================================================
