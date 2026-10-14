---- MODULE DispatchFirstOnly ----
\* Wrong neighbor: closing strikes the first call from the district and
\* leaves any others. A second call from the same district survives the
\* closure and the rule fails.
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

Struck(d) ==
  IF \E i \in DOMAIN calls : calls[i] = d
  THEN LET i == CHOOSE i \in DOMAIN calls :
                  calls[i] = d /\ \A j \in 1..(i - 1) : calls[j] /= d
       IN SubSeq(calls, 1, i - 1) \o SubSeq(calls, i + 1, Len(calls))
  ELSE calls

Close(d) ==
  /\ d \notin closed
  /\ closed' = closed \cup {d}
  /\ calls' = Struck(d)

Reopen(d) ==
  /\ d \in closed
  /\ closed' = closed \ {d}
  /\ UNCHANGED calls

Next == \E d \in Districts : Call(d) \/ Close(d) \/ Reopen(d)

Spec == Init /\ [][Next]_vars

NoClosedCalls == \A i \in DOMAIN calls : calls[i] \notin closed
====
