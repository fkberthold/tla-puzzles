---- MODULE HalvesComplete ----
\* The trap. Each half of a booking is written as a complete action,
\* holding the other variable still with UNCHANGED. The conjunction
\* then asks for takings' = takings and takings' = takings + Fare in
\* the same step, which no state satisfies. Book never fires, Refund
\* never fires, and TLC reports a deadlock in the initial state.
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
  /\ takings' = takings + Fare
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
