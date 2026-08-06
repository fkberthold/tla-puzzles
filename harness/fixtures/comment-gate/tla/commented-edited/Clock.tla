---- MODULE Clock ----
(***************************************************************************)
(* A wall clock. Tick advances seconds and rolls them over into minutes;   *)
(* Reset zeroes both. The teaching point is UNCHANGED.                     *)
(***************************************************************************)
EXTENDS Integers

VARIABLES minutes, seconds

TypeOK == minutes \in 0..59 /\ seconds \in 0..59   \* both 0-based

Init ==
  /\ minutes = 0
  /\ seconds = 0

\* The fix: every action constrains BOTH variables.
\* When seconds < 59 we tick seconds and hold minutes steady (UNCHANGED).
\* When seconds rolls over we explicitly assign both.
Tick ==
  IF seconds < 59
    THEN /\ seconds' = seconds + 1
         /\ UNCHANGED minutes
    ELSE /\ seconds' = 0
         /\ minutes' = (minutes + 1) % 24

\* Reset is unconditional: it is always enabled.
Reset ==
  /\ minutes' = 0
  /\ seconds' = 0

Next == Tick (* either one *) \/ Reset

Spec == Init /\ [][Next]_<<minutes, seconds>>
====
