---- MODULE Topped ----
\* A broken text. The characters go on correctly and every depth the string
\* stands at is written down, but so is the deepest depth the string could
\* ever reach, whether or not it ever got there.
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
  /\ rungs' = rungs \cup {open'} \cup {Limit}

Pop ==
  /\ open > 0
  /\ Len(text) < Limit
  /\ text' = Append(text, ")")
  /\ open' = open - 1
  /\ rungs' = rungs \cup {open'} \cup {Limit}

Next == Push \/ Pop

Spec == Init /\ [][Next]_vars
====
