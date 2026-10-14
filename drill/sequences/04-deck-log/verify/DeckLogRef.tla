---- MODULE DeckLogRef ----
\* Reference answer. Entries are their own numbers. Archiving moves a
\* prefix of the log onto the end of the archive in one step, and the
\* operator chooses how long the prefix is.
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
  /\ log' = SubSeq(log, k + 1, Len(log))
  /\ UNCHANGED next

Next == Write \/ Archive

Spec == Init /\ [][Next]_vars

\* The archive holds 1, 2, 3, ... and the log carries on from where the
\* archive stops. Said with the indices rather than with a counter.
Numbered ==
  /\ \A i \in DOMAIN archive : archive[i] = i
  /\ \A i \in DOMAIN log : log[i] = Len(archive) + i

NothingLost == Len(archive) + Len(log) = next - 1
====
