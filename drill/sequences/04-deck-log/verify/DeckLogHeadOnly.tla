---- MODULE DeckLogHeadOnly ----
\* Wrong neighbor: one entry archived per step, from the front. Every
\* invariant holds, because nothing is lost or misnumbered. Only the table
\* sees it, at the row where two entries move at once.
EXTENDS Naturals, Sequences

CONSTANT MaxEntry

VARIABLES log, archive, next

vars == <<log, archive, next>>

TypeOK ==
  /\ log \in Seq(1..MaxEntry)
  /\ archive \in Seq(1..MaxEntry)
  /\ next \in 1..(MaxEntry + 1)

Init ==
  /\ log = <<>>
  /\ archive = <<>>
  /\ next = 1

Write ==
  /\ next <= MaxEntry
  /\ log' = Append(log, next)
  /\ next' = next + 1
  /\ UNCHANGED archive

Archive ==
  /\ Len(log) > 0
  /\ archive' = Append(archive, Head(log))
  /\ log' = Tail(log)
  /\ UNCHANGED next

Next == Write \/ Archive

Spec == Init /\ [][Next]_vars

Numbered ==
  /\ \A i \in DOMAIN archive : archive[i] = i
  /\ \A i \in DOMAIN log : log[i] = Len(archive) + i

NothingLost == Len(archive) + Len(log) = next - 1
====
