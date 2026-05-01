---- MODULE AbstractCard ----
EXTENDS Integers

CONSTANT MaxPunches

ASSUME MaxPunches \in Nat
ASSUME MaxPunches >= 1

VARIABLE punches

vars == << punches >>

Init == punches = 0

Punch ==
  /\ \E n \in (punches+1)..MaxPunches : punches' = n

Redeem ==
  /\ punches >= MaxPunches
  /\ punches' = 0

Next == Punch \/ Redeem

Spec == Init /\ [][Next]_vars

====
