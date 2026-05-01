---- MODULE AbstractTicketing ----
EXTENDS Integers

CONSTANT MaxRequests
ASSUME MaxRequests \in Nat /\ MaxRequests >= 1

VARIABLES submitted, completed

vars == << submitted, completed >>

Init == submitted = 0 /\ completed = 0

Submit ==
  /\ submitted < MaxRequests
  /\ submitted' = submitted + 1
  /\ completed' = completed

Complete ==
  /\ completed < submitted
  /\ completed' = completed + 1
  /\ submitted' = submitted

Next == Submit \/ Complete

Spec == Init /\ [][Next]_vars
        /\ WF_vars(Submit)
        /\ SF_vars(Complete)

TypeOK == submitted \in 0..MaxRequests /\ completed \in 0..MaxRequests
Done == completed = MaxRequests
EventuallyDone == <> Done

====
