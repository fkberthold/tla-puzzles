---- MODULE PortsNoMgmtGuard ----
\* Mutant. Add no longer keeps the management port out of the range, so a
\* rule spanning it gets in and rule 1 reports it.
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
