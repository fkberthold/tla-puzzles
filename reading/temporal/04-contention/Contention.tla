---- MODULE Contention ----

Holder == {"none", "poller", "task"}

VARIABLES owner, served
vars == <<owner, served>>

TypeOK ==
  /\ owner \in Holder
  /\ served \in BOOLEAN

Init ==
  /\ owner = "none"
  /\ served = FALSE

PollTake ==
  /\ owner = "none"
  /\ owner' = "poller"
  /\ UNCHANGED served

PollDrop ==
  /\ owner = "poller"
  /\ owner' = "none"
  /\ UNCHANGED served

TaskTake ==
  /\ owner = "none"
  /\ ~served
  /\ owner' = "task"
  /\ served' = TRUE

TaskDrop ==
  /\ owner = "task"
  /\ owner' = "none"
  /\ UNCHANGED served

Next == PollTake \/ PollDrop \/ TaskTake \/ TaskDrop

Spec ==
  /\ Init /\ [][Next]_vars
  /\ WF_vars(PollTake) /\ WF_vars(PollDrop)
  /\ WF_vars(TaskDrop)
  /\ SF_vars(TaskTake)

Polls == []<><<PollDrop>>_vars

WindowCloses == (ENABLED TaskTake) ~> (~ENABLED TaskTake)

Served == <>served
====
