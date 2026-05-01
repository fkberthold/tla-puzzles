---- MODULE ConcreteQueue ----
EXTENDS Integers, Sequences

CONSTANT MaxRequests, BufferSize
ASSUME MaxRequests \in Nat /\ MaxRequests >= 1
ASSUME BufferSize \in Nat /\ BufferSize >= 1

\* Real state:
\*   queue: sequence of pending request IDs
\*   nextId: next request ID to issue
\* Auxiliary state:
\*   aux_submitted, aux_completed: counters for the refinement mapping
VARIABLES queue, nextId, aux_submitted, aux_completed

vars == << queue, nextId, aux_submitted, aux_completed >>

Init ==
  /\ queue = << >>
  /\ nextId = 1
  /\ aux_submitted = 0
  /\ aux_completed = 0

\* Client process: append a fresh ID to the queue when there's room.
ClientSubmit ==
  /\ aux_submitted < MaxRequests
  /\ Len(queue) < BufferSize
  /\ queue' = Append(queue, nextId)
  /\ nextId' = nextId + 1
  /\ aux_submitted' = aux_submitted + 1
  /\ UNCHANGED aux_completed

\* Server process: pop the head of the queue and "process" it.
ServerProcess ==
  /\ Len(queue) > 0
  /\ queue' = Tail(queue)
  /\ aux_completed' = aux_completed + 1
  /\ UNCHANGED << nextId, aux_submitted >>

Next == ClientSubmit \/ ServerProcess

Spec == Init /\ [][Next]_vars
        /\ WF_vars(ClientSubmit)
        /\ SF_vars(ServerProcess)

TypeOK ==
  /\ queue \in Seq(1..(MaxRequests+1))
  /\ nextId \in 1..(MaxRequests+1)
  /\ aux_submitted \in 0..MaxRequests
  /\ aux_completed \in 0..MaxRequests

NeverOverProcessed == aux_completed <= aux_submitted

\* Refinement to the abstract: the auxiliary counters are exactly the
\* abstract's submitted / completed.
L0 == INSTANCE AbstractTicketing WITH
  submitted <- aux_submitted,
  completed <- aux_completed
Refines == L0!Spec

\* Liveness: once all requests have been submitted, all eventually complete.
EveryRequestCompletes ==
  aux_submitted = MaxRequests ~> aux_completed = MaxRequests

====
