---- MODULE NegativeInConfig ----
\* The natural first draft: Bottom as a constant, set to -2 in the
\* config. The config parser has no negative literal and refuses the
\* file before TLC reads the module.
EXTENDS Integers

CONSTANTS Bottom, Top

VARIABLES floor, door, moving

vars == <<floor, door, moving>>

TypeOK ==
  /\ floor \in Bottom..Top
  /\ door \in {"open", "shut"}
  /\ moving \in BOOLEAN

Init ==
  /\ floor = 0
  /\ door = "open"
  /\ moving = FALSE

Open ==
  /\ ~moving
  /\ door = "shut"
  /\ door' = "open"
  /\ UNCHANGED <<floor, moving>>

Close ==
  /\ door = "open"
  /\ door' = "shut"
  /\ UNCHANGED <<floor, moving>>

Start ==
  /\ door = "shut"
  /\ ~moving
  /\ moving' = TRUE
  /\ UNCHANGED <<floor, door>>

Up ==
  /\ moving
  /\ floor < Top
  /\ floor' = floor + 1
  /\ UNCHANGED <<door, moving>>

Down ==
  /\ moving
  /\ floor > Bottom
  /\ floor' = floor - 1
  /\ UNCHANGED <<door, moving>>

Stop ==
  /\ moving
  /\ moving' = FALSE
  /\ UNCHANGED <<floor, door>>

Next == Open \/ Close \/ Start \/ Up \/ Down \/ Stop

Spec == Init /\ [][Next]_vars

DoorShutWhileMoving == moving => door = "shut"
====
