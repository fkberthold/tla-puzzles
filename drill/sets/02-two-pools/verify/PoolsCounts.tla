---- MODULE PoolsCounts ----
\* The encoding the prompt's count rules out. Two numbers, how many guards
\* at each pool. Rule 2 can be stated. Rules 1 and 3 can't, since the state
\* doesn't say who is where, and that is what kills it.
EXTENDS Naturals

CONSTANT N

VARIABLES nLanes, nLeisure

vars == <<nLanes, nLeisure>>

TypeOK == nLanes \in 0..N /\ nLeisure \in 0..N

OnBreak == N - nLanes - nLeisure

Init == nLanes = 0 /\ nLeisure = 0

JoinLanes ==
  /\ nLanes < 2
  /\ OnBreak > 0
  /\ nLanes' = nLanes + 1
  /\ UNCHANGED nLeisure

JoinLeisure ==
  /\ nLeisure < 2
  /\ OnBreak > 0
  /\ nLeisure' = nLeisure + 1
  /\ UNCHANGED nLanes

LeaveLanes ==
  /\ nLanes > 0
  /\ nLanes' = nLanes - 1
  /\ UNCHANGED nLeisure

LeaveLeisure ==
  /\ nLeisure > 0
  /\ nLeisure' = nLeisure - 1
  /\ UNCHANGED nLanes

Next == JoinLanes \/ JoinLeisure \/ LeaveLanes \/ LeaveLeisure

Spec == Init /\ [][Next]_vars

AtMostTwo == nLanes <= 2 /\ nLeisure <= 2
====
