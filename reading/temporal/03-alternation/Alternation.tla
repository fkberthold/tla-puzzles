---- MODULE Alternation ----
EXTENDS Naturals, FiniteSets

CONSTANT Proc
ASSUME Cardinality(Proc) = 2

Phase == {"idle", "hungry", "busy"}
Other(p) == CHOOSE q \in Proc : q # p

VARIABLES st, turn
vars == <<st, turn>>

TypeOK ==
  /\ st \in [Proc -> Phase]
  /\ turn \in Proc

Init ==
  /\ st = [p \in Proc |-> "idle"]
  /\ turn \in Proc

Ask(p) ==
  /\ st[p] = "idle"
  /\ st' = [st EXCEPT ![p] = "hungry"]
  /\ UNCHANGED turn

Enter(p) ==
  /\ st[p] = "hungry"
  /\ turn = p
  /\ st' = [st EXCEPT ![p] = "busy"]
  /\ UNCHANGED turn

Leave(p) ==
  /\ st[p] = "busy"
  /\ st' = [st EXCEPT ![p] = "idle"]
  /\ turn' = Other(p)

Next == \E p \in Proc : Ask(p) \/ Enter(p) \/ Leave(p)

Fairness ==
  \A p \in Proc :
    /\ WF_vars(Ask(p))
    /\ WF_vars(Enter(p))
    /\ WF_vars(Leave(p))

Spec == Init /\ [][Next]_vars /\ Fairness

OneAtATime == Cardinality({p \in Proc : st[p] = "busy"}) <= 1

NoStarvation == \A p \in Proc : []<>(st[p] = "busy")
====
