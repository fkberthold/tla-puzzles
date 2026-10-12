---- MODULE DoubleFare ----
\* A seeded defect in the correct shape: the fare is recorded twice.
\* The named obligation catches it on the second state.
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
  takings' = takings + Fare + Fare

ReleaseSeat ==
  /\ free < Seats
  /\ free' = free + 1

ReturnFare ==
  /\ takings >= Fare
  /\ takings' = takings - Fare

Book == TakeSeat /\ RecordFare

Refund == ReleaseSeat /\ ReturnFare

Next == Book \/ Refund

Spec == Init /\ [][Next]_vars

TakingsMatchSeats == takings = (Seats - free) * Fare
====
