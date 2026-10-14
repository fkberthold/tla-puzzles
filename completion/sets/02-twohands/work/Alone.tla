---- MODULE Alone ----
\* A broken clock. Both hands move correctly and the gap gets written down
\* correctly, but it writes down the hour hand a lands on whether or not
\* hand b is there too.
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
  /\ met' = met \cup {aPos'}
  /\ UNCHANGED <<aStep, bStep>>

Next == Tick

Spec == Init /\ [][Next]_vars
====
