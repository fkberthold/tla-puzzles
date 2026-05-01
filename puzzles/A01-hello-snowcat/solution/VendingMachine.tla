---- MODULE VendingMachine ----
EXTENDS Integers

VARIABLES
  \* @type: Int;
  deposit,
  \* @type: Bool;
  dispensed
vars == << deposit, dispensed >>

Init ==
  /\ deposit = 0
  /\ dispensed = FALSE

Insert ==
  /\ ~dispensed
  /\ deposit < 100
  /\ deposit' = deposit + 25
  /\ dispensed' = dispensed

Dispense ==
  /\ deposit >= 100
  /\ ~dispensed
  /\ dispensed' = TRUE
  /\ deposit' = deposit

Done ==
  /\ dispensed
  /\ UNCHANGED vars

Next == Insert \/ Dispense \/ Done

Spec == Init /\ [][Next]_vars

TypeOK == deposit \in 0..200 /\ dispensed \in BOOLEAN
====
