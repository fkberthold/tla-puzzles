---- MODULE LeaseAnswer ----
\* Reference answer. A lease is a pair, client and resource. The leased
\* resources are a projection, the second half of every pair, which is the
\* set map. A client's leases are a filter. Rule 1 counts the projection
\* against the pairs, which is only equal when no resource repeats.
EXTENDS Naturals, FiniteSets

CONSTANTS Clients, Resources, MaxHeld

VARIABLE leases

vars == <<leases>>

TypeOK == leases \subseteq Clients \X Resources

Leased == {l[2] : l \in leases}

HeldBy(c) == {l \in leases : l[1] = c}

Init == leases = {}

Grant ==
  \E c \in Clients, r \in Resources :
    /\ r \notin Leased
    /\ Cardinality(HeldBy(c)) < MaxHeld
    /\ leases' = leases \cup {<<c, r>>}

Release ==
  \E l \in leases : leases' = leases \ {l}

Next == Grant \/ Release

Spec == Init /\ [][Next]_vars

OneHolderPerResource == Cardinality(Leased) = Cardinality(leases)

WithinQuota == \A c \in Clients : Cardinality(HeldBy(c)) <= MaxHeld
====
