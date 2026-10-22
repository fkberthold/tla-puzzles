---- MODULE Conveyor ----
EXTENDS Integers, Sequences
VARIABLE belt

Init == belt = <<>>
Load == Len(belt) < 3 /\ belt' = Append(belt, Len(belt) + 1)
Clear == Len(belt) = 3 /\ belt' = <<>>
Next == Load \/ Clear
Spec == Init /\ [][Next]_<<belt>>

IsFunction == DOMAIN belt = 1..Len(belt)
Numbered == \A i \in DOMAIN belt : belt[i] = i
FirstIsHead == belt = <<>> \/ Head(belt) = belt[1]
Patched == belt = <<>> \/ [belt EXCEPT ![1] = 99][1] = 99
ZeroIndexed == belt = <<>> \/ belt[0] = belt[1]
SlicePastEnd == belt = <<>> \/ SubSeq(belt, 1, 4) = belt
=========================
