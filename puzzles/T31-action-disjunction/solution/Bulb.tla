---- MODULE Bulb ----
EXTENDS Integers

VARIABLES power, brightness

vars == <<power, brightness>>

TypeOK ==
  /\ power \in {"on", "off"}
  /\ brightness \in 0..3

Init ==
  /\ power = "off"
  /\ brightness = 0

PowerOn ==
  /\ power = "off"
  /\ power' = "on"
  /\ brightness' = 1

PowerOff ==
  /\ power = "on"
  /\ power' = "off"
  /\ brightness' = 0

Dim ==
  /\ power = "on"
  /\ brightness' \in 0..3
  /\ UNCHANGED power

Next == PowerOn \/ PowerOff \/ Dim

Spec == Init /\ [][Next]_vars
====
