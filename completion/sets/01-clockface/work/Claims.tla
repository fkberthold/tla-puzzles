---- MODULE Claims ----
\* THIS IS THE FILE YOU EDIT. Two claims are missing. Everything above them
\* is given to you, and the three machines that check them are in the other
\* files. Replace each FILL_IN marker with a TLA+ formula.
EXTENDS Naturals, FiniteSets

CONSTANT Face
ASSUME Face \in 2..24

VARIABLES step, pos, seen

Hour == 0..(Face - 1)

\* Every hour you can land on by taking some whole number of steps of size
\* s away from hour 0.
Orbit(s) == {(k * s) % Face : k \in Hour}

TypeOK ==
  /\ step \in 1..(Face - 1)
  /\ pos \in Hour
  /\ seen \in SUBSET Hour

\* CLAIM 1. The hand has never landed anywhere that taking whole steps of
\* its own step size could not have reached.
Walked == FILL_IN_CLAIM_1

\* CLAIM 2. Once the hand is back at hour 0, having moved at all, it has
\* landed on every hour its step size can reach, and nothing else.
Closes == FILL_IN_CLAIM_2
====
