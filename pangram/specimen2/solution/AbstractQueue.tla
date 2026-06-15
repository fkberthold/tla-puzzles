---- MODULE AbstractQueue ----
\* Specimen 2 (pangram set): the ABSTRACT half of an abstract <= concrete
\* refinement pair over the producer/consumer domain.
\*
\* A high-level, unbounded FIFO queue of Items.  Producers Enqueue at the tail;
\* consumers Dequeue from the head.  No capacity bound exists here -- that is
\* exactly the detail the concrete BoundedRing implementation will supply.
EXTENDS Sequences

CONSTANT Items

VARIABLE queue

vars == << queue >>

Init == queue = << >>

\* Producer appends item it to the tail.
Enqueue(it) == queue' = Append(queue, it)

\* Consumer removes the head (only when non-empty).
Dequeue ==
  /\ queue # << >>
  /\ queue' = Tail(queue)

Next ==
  \/ \E it \in Items : Enqueue(it)
  \/ Dequeue

Spec == Init /\ [][Next]_queue

TypeOK == queue \in Seq(Items)

====
