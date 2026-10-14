---- MODULE LeaseNoFreeCheck ----
\* The break-it step. Grant no longer checks that the resource is free, so
\* two clients get the same resource and rule 1 reports it.
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
    /\ Cardinality(HeldBy(c)) < MaxHeld
    /\ leases' = leases \cup {<<c, r>>}

Release ==
  \E l \in leases : leases' = leases \ {l}

Next == Grant \/ Release

Spec == Init /\ [][Next]_vars

OneHolderPerResource == Cardinality(Leased) = Cardinality(leases)

WithinQuota == \A c \in Clients : Cardinality(HeldBy(c)) <= MaxHeld
====
