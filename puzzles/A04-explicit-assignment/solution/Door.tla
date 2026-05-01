---- MODULE Door ----
EXTENDS Integers, Apalache

VARIABLES
  \* @type: Str;
  state,
  \* @type: Int;
  passes
vars == << state, passes >>

Init ==
  /\ state  := "closed"
  /\ passes := 0

Open ==
  /\ state = "closed"
  /\ passes < 3
  /\ state'  := "open"
  /\ passes' := passes + 1

Close ==
  /\ state = "open"
  /\ state'  := "closed"
  /\ passes' := passes

Lock ==
  /\ state = "closed"
  /\ state'  := "locked"
  /\ passes' := passes

Done ==
  /\ \/ state = "locked"
     \/ passes >= 3
  /\ UNCHANGED vars

Next == Open \/ Close \/ Lock \/ Done

Spec == Init /\ [][Next]_vars

TypeOK ==
  /\ state \in { "closed", "open", "locked" }
  /\ passes \in 0..5
====
