---- MODULE TrafficLight ----
EXTENDS Integers

VARIABLES color, ticks

Colors == {"red", "green", "yellow"}

TypeOK == color \in Colors /\ ticks \in 0..3

Init ==
  /\ color = "red"
  /\ ticks = 0

Tick ==
  /\ ticks < 3
  /\ ticks' = ticks + 1
  /\ color' = color

Change ==
  /\ color' = IF color = "red"   THEN "green"
              ELSE IF color = "green" THEN "yellow"
              ELSE "red"
  /\ ticks' = 0

Next == Tick \/ Change

Spec == Init /\ [][Next]_<<color, ticks>>
====
