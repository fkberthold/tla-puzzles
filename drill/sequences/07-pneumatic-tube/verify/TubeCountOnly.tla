---- MODULE TubeCountOnly ----
\* Wrong neighbour of a different kind: the module is the queue from the
\* reference, but the rule records only how many went in and came out.
\* It is true of the stack and the queue alike, so it says nothing about
\* order. Paired with the stack's Receive here to show it passing.
EXTENDS Naturals, Sequences

CONSTANT Capsules

VARIABLES tube, sentCount, receivedCount

vars == <<tube, sentCount, receivedCount>>

TypeOK ==
  /\ tube \in Seq(Capsules)
  /\ sentCount \in Nat
  /\ receivedCount \in Nat

Init ==
  /\ tube = <<>>
  /\ sentCount = 0
  /\ receivedCount = 0

Send(c) ==
  /\ tube' = Append(tube, c)
  /\ sentCount' = sentCount + 1
  /\ UNCHANGED receivedCount

Receive ==
  /\ Len(tube) > 0
  /\ receivedCount' = receivedCount + 1
  /\ tube' = SubSeq(tube, 1, Len(tube) - 1)
  /\ UNCHANGED sentCount

Next == (\E c \in Capsules : Send(c)) \/ Receive

Spec == Init /\ [][Next]_vars

NoneLost == receivedCount + Len(tube) = sentCount

SentBound == sentCount <= 4
====
