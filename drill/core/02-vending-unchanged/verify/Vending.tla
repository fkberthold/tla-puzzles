---- MODULE Vending ----
\* Reference answer. Every action says what happens to every variable,
\* and the two it leaves alone are held still with the tuple form of
\* UNCHANGED.
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
  /\ UNCHANGED <<stock, sold>>

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
