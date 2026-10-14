---- MODULE TubeSendFront ----
\* Wrong neighbour: capsules are put in at the front and taken from the
\* front, which is a stack wearing a queue's name.
EXTENDS Naturals, Sequences

CONSTANT Capsules

VARIABLES tube, sent, received

vars == <<tube, sent, received>>

TypeOK ==
  /\ tube \in Seq(Capsules)
  /\ sent \in Seq(Capsules)
  /\ received \in Seq(Capsules)

Init ==
  /\ tube = <<>>
  /\ sent = <<>>
  /\ received = <<>>

Send(c) ==
  /\ tube' = <<c>> \o tube
  /\ sent' = Append(sent, c)
  /\ UNCHANGED received

Receive ==
  /\ Len(tube) > 0
  /\ received' = Append(received, Head(tube))
  /\ tube' = Tail(tube)
  /\ UNCHANGED sent

Next == (\E c \in Capsules : Send(c)) \/ Receive

Spec == Init /\ [][Next]_vars

InOrder == received \o tube = sent

SentBound == Len(sent) <= 4
====
