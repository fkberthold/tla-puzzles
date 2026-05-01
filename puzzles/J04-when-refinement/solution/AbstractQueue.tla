---- MODULE AbstractQueue ----
\* Side B (abstract level): a queue is a sequence of items.
\* Two atomic actions: Enq adds an item; Deq removes the head.
\* Says nothing about how the queue is implemented.
EXTENDS Sequences, Naturals

CONSTANT Items, MaxLen

VARIABLE q

TypeOK ==
  /\ q \in Seq(Items)
  /\ Len(q) <= MaxLen

Init == q = << >>

Enq(x) ==
  /\ Len(q) < MaxLen
  /\ x \in Items
  /\ q' = Append(q, x)

Deq ==
  /\ Len(q) > 0
  /\ q' = Tail(q)

Next ==
  \/ \E x \in Items : Enq(x)
  \/ Deq

Spec == Init /\ [][Next]_q
================================
