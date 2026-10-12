---- MODULE TypedNextSilent ----
\* Insert forgets stock and sold, and Next opens with the typing of
\* every primed variable, the way an imperative reader declares the
\* state before using it. The forgotten variables are now free to take
\* any value in their types on every coin. TypeOK can never go red,
\* because it is being enforced rather than checked. The config checks
\* TypeOK alone, so only the state count says anything.
\*
\* Written inline rather than as TypeOK' because TLC cannot enumerate
\* successors through a primed definition: that spelling stops with
\* rc 75, "the identifier credit is either undefined or not an
\* operator".
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

Next ==
  /\ credit' \in 0..MaxCredit
  /\ stock' \in 0..Cap
  /\ sold' \in 0..Cap
  /\ \/ Insert
     \/ Vend
     \/ Refund

Spec == Init /\ [][Next]_vars

EveryCanAccountedFor == stock + sold = Cap
====
