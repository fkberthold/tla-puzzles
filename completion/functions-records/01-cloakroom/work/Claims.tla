---- MODULE Claims ----
\* THIS IS THE FILE YOU EDIT. Two claims are missing. Everything above them
\* is given to you, and the three machines that check them are in the other
\* files. Replace each FILL_IN marker with a TLA+ formula.
EXTENDS Integers, FiniteSets

CONSTANT Limit
ASSUME Limit \in 1..6

Coat == 1..4
Peg == 1..4

\* The peg a coat came in on. Coat 1 arrived on peg 1, and so on down the rail.
Own == [c \in Coat |-> c]

VARIABLES hangs, swaps

TypeOK ==
  /\ hangs \in [Coat -> Peg]
  /\ swaps \in 0..Limit

\* CLAIM 1. No peg carries two coats.
OnePerPeg == FILL_IN_CLAIM_1

\* CLAIM 2. For every swap the attendant has made, at most two coats hang
\* away from the peg they came in on.
FewMoved == FILL_IN_CLAIM_2
====
