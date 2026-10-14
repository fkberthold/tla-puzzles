---- MODULE PileRecursive ----
\* Accepted variant: reverse the top k by recursion, then join the rest
\* back on. Same states as the function literal.
EXTENDS Naturals, Sequences

CONSTANT N

VARIABLE pile

vars == <<pile>>

RECURSIVE Rev(_)
Rev(s) == IF s = <<>> THEN <<>> ELSE Append(Rev(Tail(s)), Head(s))

Flip(s, k) == Rev(SubSeq(s, 1, k)) \o SubSeq(s, k + 1, Len(s))

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
