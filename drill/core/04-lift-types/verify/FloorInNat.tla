---- MODULE FloorInNat ----
\* The type trap: floor declared over Nat. The first trip to the
\* basement makes TypeOK red.
EXTENDS Integers

CONSTANTS Basements, Top

VARIABLES floor, door, moving

vars == <<floor, door, moving>>

Bottom == -Basements

TypeOK ==
  /\ floor \in Nat
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
