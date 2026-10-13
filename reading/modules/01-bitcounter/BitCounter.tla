---- MODULE BitCounter ----
EXTENDS Naturals

VARIABLES lo, hi, shown
vars == <<lo, hi, shown>>

---- MODULE ModFour ----
VARIABLE n
MFInit == n = 0
MFNext == n' = (n + 1) % 4
MFSpec == MFInit /\ [][MFNext]_n
====

Value == (IF lo THEN 1 ELSE 0) + (IF hi THEN 2 ELSE 0)

Abs == INSTANCE ModFour WITH n <- Value

TypeOK ==
  /\ lo \in BOOLEAN
  /\ hi \in BOOLEAN
  /\ shown \in 0..3

Init == lo = FALSE /\ hi = FALSE /\ shown = 0

Tick ==
  /\ lo' = ~lo
  /\ hi' = IF lo THEN ~hi ELSE hi
  /\ UNCHANGED shown

Refresh ==
  /\ shown' = Value
  /\ UNCHANGED <<lo, hi>>

Next == Tick \/ Refresh

Spec == Init /\ [][Next]_vars

Refines == Abs!MFSpec
====
