---- MODULE Claims ----
\* THIS IS THE FILE YOU EDIT. Two claims are missing. Everything above them
\* is given to you, and the three machines that check them are in the other
\* files. Replace each FILL_IN marker with a TLA+ formula.
EXTENDS Naturals, FiniteSets

CONSTANT Site
ASSUME Cardinality(Site) > 2

VARIABLES holder, asked
vars == <<holder, asked>>

TypeOK ==
  /\ holder \in Site
  /\ asked \in SUBSET Site

\* CLAIM 1. A site that has asked for the baton does not wait for it
\* forever.
Answered == FILL_IN_CLAIM_1

\* CLAIM 2. The baton never arrives at a site that had not asked for it.
OnRequest == FILL_IN_CLAIM_2
====
