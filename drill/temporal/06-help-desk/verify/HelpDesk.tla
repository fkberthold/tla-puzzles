---- MODULE HelpDesk ----
\* The system behind drill item 06-help-desk, with one spec per candidate
\* fairness conjunct and three properties that show what each one buys.
VARIABLES customer, clerk

vars == <<customer, clerk>>

Init == /\ customer = "none"
        /\ clerk = "present"

Arrive == /\ customer = "none"
          /\ customer' = "waiting"
          /\ UNCHANGED clerk

StepAway == /\ clerk = "present"
            /\ clerk' = "absent"
            /\ UNCHANGED customer

Return == /\ clerk = "absent"
          /\ clerk' = "present"
          /\ UNCHANGED customer

Serve == /\ customer = "waiting"
         /\ clerk = "present"
         /\ customer' = "none"
         /\ UNCHANGED clerk

Next == Arrive \/ StepAway \/ Return \/ Serve

Spec == Init /\ [][Next]_vars

\* The answer.
SpecWFServe == Spec /\ WF_vars(Serve)

\* Neighbors.
SpecSFServe == Spec /\ SF_vars(Serve)
SpecWFNext  == Spec /\ WF_vars(Next)

Waiting == customer = "waiting"
Present == clerk = "present"

\* What weak fairness on Serve guarantees: a customer who waits while the
\* clerk stays at the counter is served.
ServedIfClerkStays == [](Waiting /\ []Present => <>~Waiting)

\* What it does not guarantee: every customer is served.
Served == Waiting ~> ~Waiting

\* What strong fairness on Serve would buy instead: a customer who waits
\* while the clerk keeps coming back is served.
ServedIfClerkReturns == [](Waiting /\ []<>Present => <>~Waiting)

\* What fairness on Next adds that nobody asked for: the shop never goes quiet.
NeverStops == []<><<Next>>_vars
====
