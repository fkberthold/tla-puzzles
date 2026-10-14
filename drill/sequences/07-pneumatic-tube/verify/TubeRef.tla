---- MODULE TubeRef ----
\* Reference answer. The tube is a queue. The rule about order cannot be
\* said about the tube alone, so two more lists record what went in and
\* what came out, and the rule is that the second followed by the tube is
\* the first.
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
  /\ received' = Append(received, Head(tube))
  /\ tube' = Tail(tube)
  /\ UNCHANGED sent

Next == (\E c \in Capsules : Send(c)) \/ Receive

Spec == Init /\ [][Next]_vars

InOrder == received \o tube = sent

\* Three lists and nothing in the bank stops the teller. The cfg's
\* CONSTRAINT bounds the run on the sent list, which bounds the other two.
SentBound == Len(sent) <= 4
====
