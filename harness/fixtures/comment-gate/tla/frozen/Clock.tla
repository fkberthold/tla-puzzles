---- MODULE Clock ----
EXTENDS Integers

VARIABLES minutes, seconds

TypeOK == minutes \in 0..59 /\ seconds \in 0..59

Init ==
  /\ minutes = 0
  /\ seconds = 0

Tick ==
  IF seconds < 59
    THEN /\ seconds' = seconds + 1
         /\ UNCHANGED minutes
    ELSE /\ seconds' = 0
         /\ minutes' = (minutes + 1) % 60

Reset ==
  /\ minutes' = 0
  /\ seconds' = 0

Next == Tick \/ Reset

Spec == Init /\ [][Next]_<<minutes, seconds>>
====
