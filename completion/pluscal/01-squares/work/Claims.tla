---- MODULE Claims ----
\* THIS IS THE FILE YOU EDIT. Two claims are missing. Everything above them
\* is given to you, and the three machines that check them are in the other
\* files. Replace each FILL_IN marker with a TLA+ formula.
EXTENDS Naturals

\* The four names each machine's algorithm ends up declaring. This module
\* never runs on its own. Each machine reaches your claims through the
\* `C == INSTANCE Claims` line at the bottom of its own file, and that line
\* binds every name below to the machine's own variable of the same name.
VARIABLES pc, n, r, s

TypeOK ==
  /\ n \in 0..15
  /\ r \in 0..20
  /\ s \in 1..100

\* CLAIM 1. In every state, s is the square of one more than r.
Tied == FILL_IN_CLAIM_1

\* CLAIM 2. Once the algorithm has finished, r times r is at most n, and n
\* is below s. Claim 1 is what turns those two comparisons into "r is the
\* whole-number square root of n", so neither claim says it on its own.
Landed == FILL_IN_CLAIM_2
====
