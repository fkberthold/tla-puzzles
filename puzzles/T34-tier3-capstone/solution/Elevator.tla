---- MODULE Elevator ----
EXTENDS Integers, FiniteSets

VARIABLES floor, door, direction, requests

vars == <<floor, door, direction, requests>>

Floors == 1..3

TypeOK ==
  /\ floor \in Floors
  /\ door \in {"open", "closed"}
  /\ direction \in {"up", "down", "idle"}
  /\ requests \subseteq Floors

Init ==
  /\ floor = 1
  /\ door = "closed"
  /\ direction = "idle"
  /\ requests = {}

Request ==
  \E f \in Floors :
    /\ f # floor
    /\ f \notin requests
    /\ requests' = requests \cup {f}
    /\ UNCHANGED <<floor, door, direction>>

StartUp ==
  /\ direction = "idle"
  /\ door = "closed"
  /\ \E r \in requests : r > floor
  /\ direction' = "up"
  /\ UNCHANGED <<floor, door, requests>>

StartDown ==
  /\ direction = "idle"
  /\ door = "closed"
  /\ \E r \in requests : r < floor
  /\ direction' = "down"
  /\ UNCHANGED <<floor, door, requests>>

MoveUp ==
  /\ direction = "up"
  /\ door = "closed"
  /\ floor < 3
  /\ floor' = floor + 1
  /\ UNCHANGED <<door, direction, requests>>

MoveDown ==
  /\ direction = "down"
  /\ door = "closed"
  /\ floor > 1
  /\ floor' = floor - 1
  /\ UNCHANGED <<door, direction, requests>>

OpenDoor ==
  /\ door = "closed"
  /\ floor \in requests
  /\ door' = "open"
  /\ requests' = requests \ {floor}
  /\ direction' = "idle"
  /\ UNCHANGED floor

CloseDoor ==
  /\ door = "open"
  /\ door' = "closed"
  /\ UNCHANGED <<floor, direction, requests>>

\* Abandon a committed direction when nothing in that direction is useful any more.
GoIdle ==
  /\ direction \in {"up", "down"}
  /\ door = "closed"
  /\ floor \notin requests
  /\ \/ direction = "up"   /\ ~ \E r \in requests : r > floor
     \/ direction = "down" /\ ~ \E r \in requests : r < floor
  /\ direction' = "idle"
  /\ UNCHANGED <<floor, door, requests>>

Next ==
  \/ Request
  \/ StartUp
  \/ StartDown
  \/ MoveUp
  \/ MoveDown
  \/ OpenDoor
  \/ CloseDoor
  \/ GoIdle

DoorClosedWhileMoving == (direction \in {"up", "down"}) => door = "closed"

NeverStuckClosedAtRequest == floor \in requests => door = "open"

Spec == Init /\ [][Next]_vars /\ WF_vars(Next)
====
