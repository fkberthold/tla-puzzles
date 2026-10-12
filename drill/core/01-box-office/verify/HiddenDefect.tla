---- MODULE HiddenDefect ----
\* The double fare seeded into the trapped spec. The defect is
\* invisible, because no step is ever taken: TLC reports the same
\* deadlock on the same single state as HalvesComplete.
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
  /\ UNCHANGED takings

RecordFare ==
  /\ takings' = takings + Fare + Fare
  /\ UNCHANGED free

ReleaseSeat ==
  /\ free < Seats
  /\ free' = free + 1
  /\ UNCHANGED takings

ReturnFare ==
  /\ takings >= Fare
  /\ takings' = takings - Fare
  /\ UNCHANGED free

Book == TakeSeat /\ RecordFare

Refund == ReleaseSeat /\ ReturnFare

Next == Book \/ Refund

Spec == Init /\ [][Next]_vars

TakingsMatchSeats == takings = (Seats - free) * Fare
====
