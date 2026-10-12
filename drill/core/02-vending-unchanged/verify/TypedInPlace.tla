---- MODULE TypedInPlace ----
\* Insert pins stock' and sold' to their types instead of to their
\* current values. TLC accepts it, and the machine silently restocks
\* itself on every coin.
EXTENDS Naturals

CONSTANTS Price, MaxCredit, Cap

VARIABLES credit, stock, sold

vars == <<credit, stock, sold>>

TypeOK ==
  /\ credit \in 0..MaxCredit
  /\ stock \in 0..Cap
  /\ sold \in 0..Cap

Init ==
  /\ credit = 0
  /\ stock = Cap
  /\ sold = 0

Insert ==
  /\ credit < MaxCredit
  /\ credit' \in (credit + 1)..MaxCredit
  /\ stock' \in 0..Cap
  /\ sold' \in 0..Cap

Vend ==
  /\ credit >= Price
  /\ stock > 0
  /\ credit' = credit - Price
  /\ stock' = stock - 1
  /\ sold' = sold + 1

Refund ==
  /\ credit > 0
  /\ credit' = 0
  /\ UNCHANGED <<stock, sold>>

Next == Insert \/ Vend \/ Refund

Spec == Init /\ [][Next]_vars

EveryCanAccountedFor == stock + sold = Cap
====
