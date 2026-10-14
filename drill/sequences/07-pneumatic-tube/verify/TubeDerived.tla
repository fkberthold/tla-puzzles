---- MODULE TubeDerived ----
\* Accepted variant: keep the full history and a count of how many the
\* vault has taken. The tube is then a slice of the history rather than a
\* variable, and the order rule is true by construction. Same states as
\* the reference.
EXTENDS Naturals, Sequences

CONSTANT Capsules

VARIABLES sent, taken

vars == <<sent, taken>>

Tube == SubSeq(sent, taken + 1, Len(sent))

TypeOK ==
  /\ sent \in Seq(Capsules)
  /\ taken \in 0..Len(sent)

Init ==
  /\ sent = <<>>
  /\ taken = 0

Send(c) ==
  /\ sent' = Append(sent, c)
  /\ UNCHANGED taken

Receive ==
  /\ taken < Len(sent)
  /\ taken' = taken + 1
  /\ UNCHANGED sent

Next == (\E c \in Capsules : Send(c)) \/ Receive

Spec == Init /\ [][Next]_vars

InOrder == SubSeq(sent, 1, taken) \o Tube = sent

SentBound == Len(sent) <= 4
====
