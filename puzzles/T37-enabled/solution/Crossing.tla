---- MODULE Crossing ----
EXTENDS Integers

VARIABLES light, crossings

vars == <<light, crossings>>

Init ==
  /\ light = "green"
  /\ crossings = 0

Flip ==
  /\ light' = IF light = "red" THEN "green" ELSE "red"
  /\ crossings' = crossings

Cross ==
  /\ light = "red"
  /\ crossings < 3
  /\ crossings' = crossings + 1
  /\ light' = light

Next == Flip \/ Cross

Spec == Init /\ [][Next]_vars

TypeOK == light \in {"red", "green"} /\ crossings \in 0..3

EnabledMatchesGuard == (ENABLED Cross) <=> (light = "red" /\ crossings < 3)
================================
