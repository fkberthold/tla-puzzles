---- MODULE Scheduler ----
EXTENDS Naturals, FiniteSets, Sequences, TLC

CONSTANT Jobs

VARIABLES queue, running, completed, log

vars == << queue, running, completed, log >>

\* Boundary value: WorkerSlots small (1) — exercises every contention case.
WorkerSlots == 1

Init ==
  /\ queue = Jobs
  /\ running = {}
  /\ completed = {}
  /\ log = << >>

\* Schedule a job: move from queue to running (if a slot is free).
Schedule ==
  /\ queue # {}
  /\ Cardinality(running) < WorkerSlots
  /\ \E j \in queue :
       /\ queue' = queue \ {j}
       /\ running' = running \cup {j}
       /\ log' = Append(log, j)
  /\ completed' = completed

\* Complete a running job.
Complete ==
  /\ running # {}
  /\ \E j \in running :
       /\ running' = running \ {j}
       /\ completed' = completed \cup {j}
       /\ log' = Append(log, j)
  /\ queue' = queue

Done ==
  /\ queue = {}
  /\ running = {}
  /\ UNCHANGED vars

Next == Schedule \/ Complete \/ Done

Spec == Init /\ [][Next]_vars

\* Boundary-aware TypeOK — uses the constant set, no large numbers.
TypeOK ==
  /\ queue \subseteq Jobs
  /\ running \subseteq Jobs
  /\ completed \subseteq Jobs
  /\ log \in Seq(Jobs)

\* Conservation: every job is in exactly one of queue, running, completed.
Conservation ==
  /\ queue \cup running \cup completed = Jobs
  /\ queue \cap running = {}
  /\ queue \cap completed = {}
  /\ running \cap completed = {}

\* Worker-slot bound holds always.
SlotBound == Cardinality(running) <= WorkerSlots

\* Symmetry: jobs are interchangeable model values.
JobSym == Permutations(Jobs)

\* VIEW: project away the log. The log records history but doesn't affect safety.
\* TLC will dedupe states by (queue, running, completed), ignoring log.
Project == << queue, running, completed >>

================================
