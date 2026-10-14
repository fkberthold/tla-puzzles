---- MODULE TwoHands ----
\* The real clock. Two hands on one face. Each hand's step size is picked
\* once and never changes. Both hands move on every tick.
EXTENDS Claims

vars == <<aStep, bStep, aPos, bPos, gaps, met>>

Init ==
  /\ aStep \in 1..(Face - 1)
  /\ bStep \in 1..(Face - 1)
  /\ aPos = 0
  /\ bPos = 0
  /\ gaps = {0}
  /\ met = {0}

Tick ==
  /\ aPos' = (aPos + aStep) % Face
  /\ bPos' = (bPos + bStep) % Face
  /\ gaps' = gaps \cup {Ahead(aPos', bPos')}
  /\ met' = IF aPos' = bPos' THEN met \cup {aPos'} ELSE met
  /\ UNCHANGED <<aStep, bStep>>

Next == Tick

Spec == Init /\ [][Next]_vars
====
