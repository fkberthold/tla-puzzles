---- MODULE TriageFifo ----
\* Wrong neighbor: the board as a queue. The doctor takes whoever has
\* waited longest. Row 4 of the table kills it, and so does the rule.
EXTENDS Naturals, Sequences

CONSTANT Severities

VARIABLES board, treated

vars == <<board, treated>>

TypeOK ==
  /\ board \in Seq(Severities)
  /\ treated \in Seq(Severities)
  /\ Len(board) <= 3

Init ==
  /\ board = <<>>
  /\ treated = <<>>

Arrive(s) ==
  /\ Len(board) < 3
  /\ board' = Append(board, s)
  /\ UNCHANGED treated

Take ==
  /\ Len(board) > 0
  /\ board' = Tail(board)
  /\ treated' = Append(treated, Head(board))

Next == (\E s \in Severities : Arrive(s)) \/ Take

Spec == Init /\ [][Next]_vars

MostUrgentFirst ==
  [][Len(treated') = Len(treated) + 1 =>
       \A i \in DOMAIN board : treated'[Len(treated')] <= board[i]]_vars

TreatedBound == Len(treated) <= 3
====
