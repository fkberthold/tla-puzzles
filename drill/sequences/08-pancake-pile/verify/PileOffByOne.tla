---- MODULE PileOffByOne ----
\* Wrong neighbour: the mirror index written as k - i. At i = k that is
\* index 0, which no list has, and TLC stops in the first flip.
EXTENDS Naturals, Sequences

CONSTANT N

VARIABLE pile

vars == <<pile>>

Flip(s, k) == [i \in 1..Len(s) |-> IF i <= k THEN s[k - i] ELSE s[i]]

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
