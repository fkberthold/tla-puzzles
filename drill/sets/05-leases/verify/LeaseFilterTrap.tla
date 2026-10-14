---- MODULE LeaseFilterTrap ----
\* The trap. Leased is written as a filter where a projection was meant, so
\* it is the set of pairs again rather than the set of resources. The free
\* check then compares a resource against pairs and always passes, and rule
\* 1 compares a count with itself. Nothing in the config reports anything.
EXTENDS Naturals, FiniteSets

CONSTANTS Clients, Resources, MaxHeld

VARIABLE leases

vars == <<leases>>

TypeOK == leases \subseteq Clients \X Resources

Leased == {l \in leases : l[2] \in Resources}

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
