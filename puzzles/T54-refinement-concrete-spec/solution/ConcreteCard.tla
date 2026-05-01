---- MODULE ConcreteCard ----
EXTENDS Integers

CONSTANT MaxPunches

ASSUME MaxPunches \in Nat
ASSUME MaxPunches >= 1

VARIABLES punches, lastAction

vars == << punches, lastAction >>

Init ==
  /\ punches = 0
  /\ lastAction = "none"

Punch ==
  /\ punches < MaxPunches
  /\ punches' = punches + 1
  /\ lastAction' = "punch"

Redeem ==
  /\ punches = MaxPunches
  /\ punches' = 0
  /\ lastAction' = "redeem"

Next == Punch \/ Redeem

Spec == Init /\ [][Next]_vars

TypeOK ==
  /\ punches \in 0..MaxPunches
  /\ lastAction \in {"none", "punch", "redeem"}

\* Refinement: the concrete spec implements the abstract.
L0 == INSTANCE AbstractCard
Refines == L0!Spec

====
