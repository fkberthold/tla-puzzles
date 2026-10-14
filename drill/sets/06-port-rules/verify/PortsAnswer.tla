---- MODULE PortsAnswer ----
\* Reference answer. A rule is a pair, lowest and highest port. The open
\* ports are the flattening of every rule's interval, which is where the
\* set map and the big union meet. The switch is a Boolean.
EXTENDS Naturals, FiniteSets

CONSTANTS Lo, Hi, Mgmt, MaxRules

Allowed == Lo..Hi
Typed == (Lo - 1)..(Hi + 1)

VARIABLES rules, maint

vars == <<rules, maint>>

Covered(r) == r[1]..r[2]

Open == UNION {Covered(r) : r \in rules}

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
