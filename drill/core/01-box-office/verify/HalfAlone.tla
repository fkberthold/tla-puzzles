---- MODULE HalfAlone ----
\* The other way to get the halves wrong: a partial action placed in
\* Next on its own. Book says nothing about takings', so TLC cannot
\* build a successor state and refuses rather than guessing.
EXTENDS Naturals

CONSTANTS Seats, Fare

VARIABLES free, takings

vars == <<free, takings>>

TypeOK ==
  /\ free \in 0..Seats
  /\ takings \in Nat

Init ==
  /\ free = Seats
  /\ takings = 0

TakeSeat ==
  /\ free > 0
  /\ free' = free - 1

RecordFare ==
  takings' = takings + Fare

ReleaseSeat ==
  /\ free < Seats
  /\ free' = free + 1

ReturnFare ==
  /\ takings >= Fare
  /\ takings' = takings - Fare

Book == TakeSeat

Refund == ReleaseSeat /\ ReturnFare

Next == Book \/ Refund

Spec == Init /\ [][Next]_vars

TakingsMatchSeats == takings = (Seats - free) * Fare
====
