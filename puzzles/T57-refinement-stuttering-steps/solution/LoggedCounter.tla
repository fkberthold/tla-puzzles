---- MODULE LoggedCounter ----
EXTENDS Integers

CONSTANT Max
ASSUME Max \in Nat /\ Max >= 1

VARIABLES n, lastLog

vars == << n, lastLog >>

Init ==
  /\ n = 0
  /\ lastLog = "init"

Inc ==
  /\ n < Max
  /\ n' = n + 1
  /\ lastLog' = "incremented"

Log ==
  /\ lastLog' = "no-op"
  /\ UNCHANGED n

Next == Inc \/ Log

Spec == Init /\ [][Next]_vars

TypeOK ==
  /\ n \in 0..Max
  /\ lastLog \in {"init", "incremented", "no-op"}

\* Refinement: project to n. Log is a stutter on n; Inc matches abstract Inc.
L0 == INSTANCE Counter WITH n <- n
Refines == L0!Spec

====
