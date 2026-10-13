---- MODULE Brackets ----
EXTENDS Integers, Sequences

CONSTANT Limit
ASSUME Limit \in Nat

VARIABLES text, open
vars == <<text, open>>

Opens(t)  == Len(SelectSeq(t, LAMBDA c : c = "("))
Closes(t) == Len(t) - Opens(t)

TypeOK ==
  /\ \A i \in 1..Len(text) : text[i] \in {"(", ")"}
  /\ open \in 0..Limit

Init ==
  /\ text = <<>>
  /\ open = 0

Push ==
  /\ Len(text) < Limit
  /\ text' = Append(text, "(")
  /\ open' = open + 1

Pop ==
  /\ open > 0
  /\ Len(text) < Limit
  /\ text' = Append(text, ")")
  /\ open' = open - 1

Next == Push \/ Pop

Spec == Init /\ [][Next]_vars

Surplus == open = Opens(text) - Closes(text)

PrefixSound ==
  \A i \in 0..Len(text) :
    Opens(SubSeq(text, 1, i)) >= Closes(SubSeq(text, 1, i))
====
