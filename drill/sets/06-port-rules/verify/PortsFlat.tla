---- MODULE PortsFlat ----
\* Wrong neighbour. Open is the set of intervals rather than the set of
\* ports, because the flattening was left out. Both rules then compare a
\* number against a set of sets, and what TLC does with that is measured
\* in the answer rather than guessed.
EXTENDS Naturals, FiniteSets

CONSTANTS Lo, Hi, Mgmt, MaxRules

Allowed == Lo..Hi
Typed == (Lo - 1)..(Hi + 1)

VARIABLES rules, maint

vars == <<rules, maint>>

Covered(r) == r[1]..r[2]

Open == {Covered(r) : r \in rules}

TypeOK ==
  /\ rules \subseteq Typed \X Typed
  /\ maint \in BOOLEAN

Init == rules = {} /\ maint = FALSE

Add ==
  /\ ~maint
  /\ Cardinality(rules) < MaxRules
  /\ \E a, b \in Typed :
       /\ a <= b
       /\ a..b \subseteq Allowed
       /\ Mgmt \notin a..b
       /\ rules' = rules \cup {<<a, b>>}
  /\ UNCHANGED maint

Remove ==
  /\ \E r \in rules : rules' = rules \ {r}
  /\ UNCHANGED maint

Toggle == maint' = ~maint /\ UNCHANGED rules

Next == Add \/ Remove \/ Toggle

Spec == Init /\ [][Next]_vars

ManagementClosed == Mgmt \notin Open

WithinAllowed == Open \subseteq Allowed
====
