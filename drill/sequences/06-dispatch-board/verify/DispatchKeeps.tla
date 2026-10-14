---- MODULE DispatchKeeps ----
\* Wrong neighbour: the filter test written the wrong way round. It keeps
\* the calls from the closed district and strikes everything else.
EXTENDS Naturals, Sequences

CONSTANT Districts

VARIABLES calls, closed

vars == <<calls, closed>>

TypeOK ==
  /\ calls \in Seq(Districts)
  /\ Len(calls) <= 3
  /\ closed \subseteq Districts

Init ==
  /\ calls = <<>>
  /\ closed = {}

Call(d) ==
  /\ d \notin closed
  /\ Len(calls) < 3
  /\ calls' = Append(calls, d)
  /\ UNCHANGED closed

Close(d) ==
  /\ d \notin closed
  /\ closed' = closed \cup {d}
  /\ calls' = SelectSeq(calls, LAMBDA c : c = d)

Reopen(d) ==
  /\ d \in closed
  /\ closed' = closed \ {d}
  /\ UNCHANGED calls

Next == \E d \in Districts : Call(d) \/ Close(d) \/ Reopen(d)

Spec == Init /\ [][Next]_vars

NoClosedCalls == \A i \in DOMAIN calls : calls[i] \notin closed
====
