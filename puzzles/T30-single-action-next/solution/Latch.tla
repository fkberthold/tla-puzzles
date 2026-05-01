---- MODULE Latch ----
EXTENDS Integers

VARIABLES value, latched

TypeOK == value \in 0..9 /\ latched \in BOOLEAN

Init ==
  /\ value \in 0..9
  /\ latched = FALSE

Latch ==
  /\ latched = FALSE
  /\ latched' = TRUE
  /\ value' = 0

Next == Latch

Spec == Init /\ [][Next]_<<value, latched>>
====
