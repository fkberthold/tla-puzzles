---- MODULE PubAnswer ----
\* Reference answer. A vote is a pair, friend and pub. Committed is a count
\* over a filter against a count of the friends, and the rule quantifies
\* over two pubs at once.
EXTENDS Naturals, FiniteSets

CONSTANTS Friends, Pubs

VARIABLE votes

vars == <<votes>>

TypeOK == votes \subseteq Friends \X Pubs

Voted == {v[1] : v \in votes}

VotesFor(p) == {v \in votes : v[2] = p}

Committed(p) == 2 * Cardinality(VotesFor(p)) > Cardinality(Friends)

Init == votes = {}

Vote ==
  \E f \in Friends \ Voted, p \in Pubs :
    votes' = votes \cup {<<f, p>>}

Next == Vote

Spec == Init /\ [][Next]_vars

OneVoteEach == \A v, w \in votes : v[1] = w[1] => v = w

OnePubAtMost == \A p, q \in Pubs : Committed(p) /\ Committed(q) => p = q
====
