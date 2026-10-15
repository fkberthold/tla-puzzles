---- MODULE Break ----
CONSTANT Player

VARIABLES playing, asked
vars == <<playing, asked>>

AllIdle == \A p \in Player : ~playing[p]

TypeOK ==
  /\ playing \in [Player -> BOOLEAN]
  /\ asked \in BOOLEAN

Init ==
  /\ playing = [p \in Player |-> FALSE]
  /\ asked = FALSE

Start(p) ==
  /\ ~asked
  /\ ~playing[p]
  /\ playing' = [playing EXCEPT ![p] = TRUE]
  /\ UNCHANGED asked

Stop(p) ==
  /\ playing[p]
  /\ playing' = [playing EXCEPT ![p] = FALSE]
  /\ UNCHANGED asked

Ask ==
  /\ ~asked
  /\ asked' = TRUE
  /\ UNCHANGED playing

Resume ==
  /\ asked
  /\ AllIdle
  /\ asked' = FALSE
  /\ UNCHANGED playing

Next ==
  \/ \E p \in Player : Start(p) \/ Stop(p)
  \/ Ask
  \/ Resume

Fairness ==
  /\ \A p \in Player : WF_vars(Stop(p))
  /\ WF_vars(Resume)

Spec == Init /\ [][Next]_vars /\ Fairness

BreakArrives == asked ~> AllIdle

NoFreshStart ==
  [][asked => \A p \in Player : playing'[p] => playing[p]]_vars
====
