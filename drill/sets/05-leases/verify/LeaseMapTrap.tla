---- MODULE LeaseMapTrap ----
\* The other trap. HeldBy is written as a map where a filter was meant, so
\* it is a set of truth values with at most two members. The quota check
\* and rule 2 both count that set, and neither can ever see a third lease.
EXTENDS Naturals, FiniteSets

CONSTANTS Clients, Resources, MaxHeld

VARIABLE leases

vars == <<leases>>

TypeOK == leases \subseteq Clients \X Resources

Leased == {l[2] : l \in leases}

HeldBy(c) == {l[1] = c : l \in leases}

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
