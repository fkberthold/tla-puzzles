---- MODULE Clock_buggy ----
EXTENDS Integers

VARIABLES minutes, seconds

TypeOK == minutes \in 0..59 /\ seconds \in 0..59

Init ==
  /\ minutes = 0
  /\ seconds = 0

\* BUG: the non-rollover branch forgets to constrain minutes'.
\* Fix: add  /\ UNCHANGED minutes  to the THEN/ELSE that needs it.
Tick ==
  IF seconds < 59
    THEN seconds' = seconds + 1
    ELSE /\ seconds' = 0
         /\ minutes' = (minutes + 1) % 60

Reset ==
  /\ minutes' = 0
  /\ seconds' = 0

Next == Tick \/ Reset

Spec == Init /\ [][Next]_<<minutes, seconds>>
====
