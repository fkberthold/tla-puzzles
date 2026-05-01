---- MODULE Game ----
EXTENDS Integers

VARIABLES score, strikes

vars == <<score, strikes>>

TypeOK == score \in 0..9 /\ strikes \in 0..3

Init ==
  /\ score = 0
  /\ strikes = 0

Hit ==
  /\ strikes < 3
  /\ score < 9
  /\ score' = score + 1
  /\ strikes' = 0

Strike ==
  /\ strikes < 3
  /\ strikes' = strikes + 1
  /\ UNCHANGED score

StrikeOut ==
  /\ strikes = 3
  /\ strikes' = 0
  /\ score' = 0

Next == Hit \/ Strike \/ StrikeOut

NoScoreWhenStruckOut == strikes = 3 => score = 0

Spec == Init /\ [][Next]_vars
====
