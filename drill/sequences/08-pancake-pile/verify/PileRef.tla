---- MODULE PileRef ----
\* Reference answer. No operator in the module reverses anything, so the
\* flip is built as a function on 1..Len. A list is a function on 1..n,
\* and that is the whole trick. Init uses the same fact the other way:
\* the arrangements are the functions on 1..N that hit every size once.
EXTENDS Naturals, Sequences

CONSTANT N

VARIABLE pile

vars == <<pile>>

Flip(s, k) == [i \in 1..Len(s) |-> IF i <= k THEN s[k + 1 - i] ELSE s[i]]

\* The same N pancakes, each still present once, whatever the order.
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
