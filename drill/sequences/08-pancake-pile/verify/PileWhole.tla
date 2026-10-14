---- MODULE PileWhole ----
\* Wrong neighbor: every flip turns the whole pile over, whatever k is.
\* The invariant holds. Row 1 of the table, a flip of the top two, does
\* not.
EXTENDS Naturals, Sequences

CONSTANT N

VARIABLE pile

vars == <<pile>>

Flip(s, k) == [i \in 1..Len(s) |-> s[Len(s) + 1 - i]]

SamePancakes ==
  /\ Len(pile) = N
  /\ \A s \in 1..N : \E i \in DOMAIN pile : pile[i] = s

TypeOK ==
  /\ pile \in Seq(1..N)
  /\ Len(pile) = N

Init ==
  /\ pile \in [1..N -> 1..N]
  /\ SamePancakes

Turn == \E k \in 2..N : pile' = Flip(pile, k)

Next == Turn

Spec == Init /\ [][Next]_vars
====
