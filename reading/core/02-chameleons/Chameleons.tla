---- MODULE Chameleons ----
EXTENDS Integers

Color == 1..3
Start == <<1, 2, 3>>
Total == Start[1] + Start[2] + Start[3]

VARIABLE count
vars == <<count>>

TypeOK == count \in [Color -> 0..Total]

Init == count = Start

\* Two chameleons of different colors meet, and each one takes on the
\* third color.
Meet(i, j) ==
  /\ i # j
  /\ count[i] > 0
  /\ count[j] > 0
  /\ count' = [k \in Color |->
                 CASE k = i -> count[k] - 1
                   [] k = j -> count[k] - 1
                   [] OTHER -> count[k] + 2]

Next == \E i, j \in Color : Meet(i, j)

Spec == Init /\ [][Next]_vars

Conserved == count[1] + count[2] + count[3] = Total

Spread ==
  \A i, j \in Color : i # j => (count[i] - count[j]) % 3 # 0

NeverOneColor == \A i \in Color : count[i] # Total
====
