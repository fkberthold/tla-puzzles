---- MODULE Claims ----
\* THIS IS THE FILE YOU EDIT. Two claims are missing. Everything above them
\* is given to you, and the three machines that check them are in the other
\* files. Replace each FILL_IN marker with a TLA+ formula.
EXTENDS Naturals, FiniteSets

CONSTANT Face
ASSUME Face \in 2..24

VARIABLES aStep, bStep, aPos, bPos, gaps, met

Hour == 0..(Face - 1)

\* Every hour you can land on by taking some whole number of steps of size
\* s away from hour 0.
Orbit(s) == {(k * s) % Face : k \in Hour}

\* How far hour y sits ahead of hour x, counted forwards round the face so
\* the answer is itself an hour.
Ahead(x, y) == (y + Face - x) % Face

TypeOK ==
  /\ aStep \in 1..(Face - 1)
  /\ bStep \in 1..(Face - 1)
  /\ aPos \in Hour
  /\ bPos \in Hour
  /\ gaps \in SUBSET Hour
  /\ met \in SUBSET Hour

\* CLAIM 1. Every gap the two hands have stood at is one that whole steps of
\* the gap's own step size could have reached.
Tracks == FILL_IN_CLAIM_1

\* CLAIM 2. Every hour the two hands have shared is one that whole steps of
\* either hand could have reached.
Shared == FILL_IN_CLAIM_2
====
