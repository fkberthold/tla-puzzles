---- MODULE Lift ----
\* Reference answer. The floor can be negative, so the type invariant
\* ranges over Bottom..Top and the module extends Integers.
\*
\* Bottom is a definition rather than a constant because a .cfg file
\* cannot carry a negative literal: "Bottom = -2" is refused with
\* "expecting = or <-". The constant is the basement count instead.
EXTENDS Integers

CONSTANTS Basements, Top

VARIABLES floor, door, moving

vars == <<floor, door, moving>>

Bottom == -Basements

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
