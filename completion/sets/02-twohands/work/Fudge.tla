---- MODULE Fudge ----
\* A broken clock. Both hands move correctly and the hours they share are
\* written down correctly, but the gap gets written down one hour too far
\* ahead.
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
  /\ gaps' = gaps \cup {(Ahead(aPos', bPos') + 1) % Face}
  /\ met' = IF aPos' = bPos' THEN met \cup {aPos'} ELSE met
  /\ UNCHANGED <<aStep, bStep>>

Next == Tick

Spec == Init /\ [][Next]_vars
====
