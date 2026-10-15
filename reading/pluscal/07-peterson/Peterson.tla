---- MODULE Peterson ----
EXTENDS FiniteSets

CONSTANT Proc
ASSUME Cardinality(Proc) = 2

Label == {"ncs", "set", "wait", "cs", "exit"}
Other(p) == CHOOSE q \in Proc : q # p

VARIABLES flag, turn, pc
vars == <<flag, turn, pc>>

TypeOK == /\ flag \in [Proc -> BOOLEAN]
          /\ turn \in Proc
          /\ pc \in [Proc -> Label]

Init == /\ flag = [p \in Proc |-> FALSE]
        /\ turn \in Proc
        /\ pc = [p \in Proc |-> "ncs"]

Trans(p, from, to) == pc[p] = from /\ pc' = [pc EXCEPT ![p] = to]

Raise(p) == /\ Trans(p, "ncs", "set")
            /\ flag' = [flag EXCEPT ![p] = TRUE]
            /\ UNCHANGED turn

Yield(p) == /\ Trans(p, "set", "wait")
            /\ turn' = Other(p)
            /\ UNCHANGED flag

Enter(p) == /\ Trans(p, "wait", "cs")
            /\ (~flag[Other(p)] \/ turn = p)
            /\ UNCHANGED <<flag, turn>>

Work(p) == Trans(p, "cs", "exit") /\ UNCHANGED <<flag, turn>>

Drop(p) == /\ Trans(p, "exit", "ncs")
           /\ flag' = [flag EXCEPT ![p] = FALSE]
           /\ UNCHANGED turn

Step(p) == Raise(p) \/ Yield(p) \/ Enter(p) \/ Work(p) \/ Drop(p)
Next == \E p \in Proc : Step(p)

Fairness == \A p \in Proc : /\ WF_vars(Yield(p))
                            /\ WF_vars(Enter(p))
                            /\ WF_vars(Work(p))
                            /\ WF_vars(Drop(p))

Spec == Init /\ [][Next]_vars /\ Fairness

InCS(p) == pc[p] \in {"cs", "exit"}
MutEx == \A p \in Proc : InCS(p) => ~InCS(Other(p))

TurnIsGiven ==
  [][\A p \in Proc : turn' = p /\ turn # p => pc[Other(p)] = "set"]_vars

Waiting == \A p \in Proc : (pc[p] = "wait") ~> InCS(p)
====
