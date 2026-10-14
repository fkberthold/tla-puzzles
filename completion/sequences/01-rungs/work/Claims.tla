---- MODULE Claims ----
\* THIS IS THE FILE YOU EDIT. Two claims are missing. Everything above them
\* is given to you, and the three machines that check them are in the other
\* files. Replace each FILL_IN marker with a TLA+ formula.
EXTENDS Integers, FiniteSets, Sequences

CONSTANT Limit
ASSUME Limit \in Nat

Mark == {"(", ")"}

VARIABLES text, open, rungs

\* How many brackets a text leaves open: the "(" in it, less the ")".
Depth(t) ==
  Len(SelectSeq(t, LAMBDA c : c = "(")) - Len(SelectSeq(t, LAMBDA c : c = ")"))

TypeOK ==
  /\ text \in Seq(Mark)
  /\ open \in 0..Limit
  /\ rungs \in SUBSET (0..Limit)

\* CLAIM 1. The depths written down climb from nothing open upwards with no
\* depth missing in between.
Ladder == FILL_IN_CLAIM_1

\* CLAIM 2. Every prefix of the text leaves the string at a depth that is
\* written down.
Standing == FILL_IN_CLAIM_2
====
