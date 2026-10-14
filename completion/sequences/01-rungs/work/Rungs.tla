---- MODULE Rungs ----
\* The real text. One character goes on the end at a time, and every depth
\* the string stands at goes into rungs as it is reached.
EXTENDS Claims

vars == <<text, open, rungs>>

Init ==
  /\ text = <<>>
  /\ open = 0
  /\ rungs = {0}

Push ==
  /\ Len(text) < Limit
  /\ text' = Append(text, "(")
  /\ open' = open + 1
  /\ rungs' = rungs \cup {open'}

Pop ==
  /\ open > 0
  /\ Len(text) < Limit
  /\ text' = Append(text, ")")
  /\ open' = open - 1
  /\ rungs' = rungs \cup {open'}

Next == Push \/ Pop

Spec == Init /\ [][Next]_vars
====
