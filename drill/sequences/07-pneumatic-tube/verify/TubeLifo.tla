---- MODULE TubeLifo ----
\* Wrong neighbor: the vault takes the capsule that went in last. The
\* order rule fails as soon as two capsules are in the tube together.
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
  /\ tube' = Append(tube, c)
  /\ sent' = Append(sent, c)
  /\ UNCHANGED received

Receive ==
  /\ Len(tube) > 0
  /\ received' = Append(received, tube[Len(tube)])
  /\ tube' = SubSeq(tube, 1, Len(tube) - 1)
  /\ UNCHANGED sent

Next == (\E c \in Capsules : Send(c)) \/ Receive

Spec == Init /\ [][Next]_vars

InOrder == received \o tube = sent

SentBound == Len(sent) <= 4
====
