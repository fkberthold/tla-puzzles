---- MODULE Claims ----
\* THIS IS THE FILE YOU EDIT. Two claims are missing. Everything above them
\* is given to you, and the three machines that check them are in the other
\* files. Replace each FILL_IN marker with a TLA+ formula.
EXTENDS Naturals, FiniteSets

CONSTANTS Door, Answer, Nil, Limit
ASSUME Nil \notin Answer

VARIABLES noted, heard, calls
vars == <<noted, heard, calls>>

TypeOK ==
  /\ noted \in [Door -> Answer \cup {Nil}]
  /\ heard \in SUBSET Answer
  /\ calls \in Nat

\* The search bound, and it is given rather than asked for. calls climbs on
\* every knock and nothing ever lowers it, so without this the reachable
\* state space is infinite and the run does not finish. Each machine's .cfg
\* names it on a CONSTRAINT line, which is how a keyword in a .cfg reaches
\* an operator defined here.
Bounded == calls \in 0..Limit

\* CLAIM 1. Nothing is written against a door that the canvasser does not
\* also remember hearing.
Known == FILL_IN_CLAIM_1

\* CLAIM 2. The canvasser cannot have heard more distinct answers than the
\* number of doors knocked on.
Counted == FILL_IN_CLAIM_2
====
