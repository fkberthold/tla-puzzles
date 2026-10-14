---- MODULE DeckLogOffByOne ----
\* Wrong neighbour: the log keeps entry k after archiving it. The slice
\* starts at k rather than k + 1, and the numbering rule fails on the first
\* archive.
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

Archive == \E k \in 1..Len(log) :
  /\ archive' = archive \o SubSeq(log, 1, k)
  /\ log' = SubSeq(log, k, Len(log))
  /\ UNCHANGED next

Next == Write \/ Archive

Spec == Init /\ [][Next]_vars

Numbered ==
  /\ \A i \in DOMAIN archive : archive[i] = i
  /\ \A i \in DOMAIN log : log[i] = Len(archive) + i

NothingLost == Len(archive) + Len(log) = next - 1
====
