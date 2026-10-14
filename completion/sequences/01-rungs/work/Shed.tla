---- MODULE Shed ----
\* A broken text. The characters go on correctly and every depth the string
\* reaches is written down, but when a bracket closes, the depth the string
\* has just left is struck off again.
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
  /\ rungs' = rungs \ {open}

Next == Push \/ Pop

Spec == Init /\ [][Next]_vars
====
