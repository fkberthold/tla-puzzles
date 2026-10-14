---- MODULE DispatchRecursive ----
\* Accepted variant: the filter written by hand as a recursive operator.
\* Same states, more lines, and it is what you write when you have
\* forgotten the module has a filter.
EXTENDS Naturals, Sequences

CONSTANT Districts

VARIABLES calls, closed

vars == <<calls, closed>>

RECURSIVE Without(_, _)
Without(s, d) ==
  IF s = <<>> THEN <<>>
  ELSE IF Head(s) = d THEN Without(Tail(s), d)
  ELSE <<Head(s)>> \o Without(Tail(s), d)

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
  /\ calls' = Without(calls, d)

Reopen(d) ==
  /\ d \in closed
  /\ closed' = closed \ {d}
  /\ UNCHANGED calls

Next == \E d \in Districts : Call(d) \/ Close(d) \/ Reopen(d)

Spec == Init /\ [][Next]_vars

NoClosedCalls == \A i \in DOMAIN calls : calls[i] \notin closed
====
