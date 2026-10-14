------------------------------ MODULE Signal ------------------------------
\* The coarse machine. Three colors in a fixed cycle, nothing else.
VARIABLE color

Init == color = "red"

Next ==
    \/ color = "red"   /\ color' = "green"
    \/ color = "green" /\ color' = "amber"
    \/ color = "amber" /\ color' = "red"

Spec == Init /\ [][Next]_color

=============================================================================
