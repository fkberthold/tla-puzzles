---- MODULE TriageRef ----
\* Reference answer. The doctor takes the lowest severity wherever it sits
\* on the board, so the board is cut around an index rather than popped
\* from the front.
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
  /\ LET i == CHOOSE i \in DOMAIN board :
                \A j \in DOMAIN board : board[i] <= board[j]
     IN /\ board' = SubSeq(board, 1, i - 1) \o SubSeq(board, i + 1, Len(board))
        /\ treated' = Append(treated, board[i])

Next == (\E s \in Severities : Arrive(s)) \/ Take

Spec == Init /\ [][Next]_vars

\* The doctor's rule: whenever the treated list grows, the severity it grew
\* by is no larger than any severity that was on the board.
MostUrgentFirst ==
  [][Len(treated') = Len(treated) + 1 =>
       \A i \in DOMAIN board : treated'[Len(treated')] <= board[i]]_vars

\* The treated list grows for ever. The run is bounded here, in the cfg's
\* CONSTRAINT, rather than by a guard, because nothing in the clinic stops
\* the doctor working.
TreatedBound == Len(treated) <= 3
====
