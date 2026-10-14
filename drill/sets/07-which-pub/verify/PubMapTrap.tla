---- MODULE PubMapTrap ----
\* The trap on the broken model. The half threshold is in, and VotesFor is
\* written as a map where a filter was meant, so it is a set of truth values
\* with at most two members. Two votes never look like half of four, nobody
\* is ever committed, and the rule holds for the wrong reason.
EXTENDS Naturals, FiniteSets

CONSTANTS Friends, Pubs

VARIABLE votes

vars == <<votes>>

TypeOK == votes \subseteq Friends \X Pubs

Voted == {v[1] : v \in votes}

VotesFor(p) == {v[2] = p : v \in votes}

Committed(p) == 2 * Cardinality(VotesFor(p)) >= Cardinality(Friends)

Init == votes = {}

Vote ==
  \E f \in Friends \ Voted, p \in Pubs :
    votes' = votes \cup {<<f, p>>}

Next == Vote

Spec == Init /\ [][Next]_vars

OneVoteEach == \A v, w \in votes : v[1] = w[1] => v = w

OnePubAtMost == \A p, q \in Pubs : Committed(p) /\ Committed(q) => p = q
====
