---- MODULE LeaseNoQuotaCheck ----
\* Mutant. Grant no longer checks the client's quota, so one client takes
\* all three resources and rule 2 reports it.
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
    /\ leases' = leases \cup {<<c, r>>}

Release ==
  \E l \in leases : leases' = leases \ {l}

Next == Grant \/ Release

Spec == Init /\ [][Next]_vars

OneHolderPerResource == Cardinality(Leased) = Cardinality(leases)

WithinQuota == \A c \in Clients : Cardinality(HeldBy(c)) <= MaxHeld
====
