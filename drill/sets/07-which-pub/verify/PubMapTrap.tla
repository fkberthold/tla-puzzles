---- MODULE PubMapTrap ----
\* The trap on the broken model. The half threshold is in, and VotesFor is
\* written as a map where a filter was meant, so it is a set of truth values
\* with at most two members. At the half threshold two members are enough, so
\* one vote for one pub and one for another makes both read as committed and
\* the rule reports it after two votes. Measured 2026-10-14: rc 12, 17
\* distinct. The same map on the correct threshold is silent, which is
\* PubMapTrapStrict. Loud here, quiet there, one error.
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
