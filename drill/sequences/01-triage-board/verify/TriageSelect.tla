---- MODULE TriageSelect ----
\* Wrong neighbor: the minimum is found and then every patient at that
\* severity is removed at once by a filter. The rule cannot see this, since
\* the one who was treated really was the most urgent. Row 9 of the table
\* sees it: two patients at 4, one taken, one still waiting.
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
  /\ LET m == CHOOSE m \in {board[i] : i \in DOMAIN board} :
                \A j \in DOMAIN board : m <= board[j]
     IN /\ board' = SelectSeq(board, LAMBDA s : s /= m)
        /\ treated' = Append(treated, m)

Next == (\E s \in Severities : Arrive(s)) \/ Take

Spec == Init /\ [][Next]_vars

MostUrgentFirst ==
  [][Len(treated') = Len(treated) + 1 =>
       \A i \in DOMAIN board : treated'[Len(treated')] <= board[i]]_vars

TreatedBound == Len(treated) <= 3
====
