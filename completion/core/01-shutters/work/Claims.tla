---- MODULE Claims ----
\* THIS IS THE FILE YOU EDIT. Two claims are missing. Everything above them
\* is given to you, and the three machines that check them are in the other
\* files. Replace each FILL_IN marker with a TLA+ formula.
EXTENDS Integers, FiniteSets

CONSTANT Limit
ASSUME Limit \in 2..12

Shutter == 1..5

VARIABLES open, pulls

TypeOK ==
  /\ open \in SUBSET Shutter
  /\ pulls \in 0..Limit

\* CLAIM 1. The count of open shutters is never odd.
EvenOpen == FILL_IN_CLAIM_1

\* CLAIM 2. Once the shopfront is shut again, with the catch worked at least
\* once, the catch has been worked an even number of times.
ShutEvenly == FILL_IN_CLAIM_2
====
