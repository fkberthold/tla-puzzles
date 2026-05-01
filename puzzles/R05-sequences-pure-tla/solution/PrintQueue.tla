---- MODULE PrintQueue ----
EXTENDS Integers, Sequences

Jobs == 1..3

VARIABLE queue

TypeOK == queue \in Seq(Jobs) /\ Len(queue) <= 3

Init == queue = <<>>

Submit ==
  \E j \in Jobs :
    /\ \A i \in 1..Len(queue) : queue[i] # j
    /\ queue' = Append(queue, j)

Print ==
  /\ Len(queue) > 0
  /\ queue' = Tail(queue)

Next == Submit \/ Print

Spec == Init /\ [][Next]_queue
====
