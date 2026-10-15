---- MODULE Cycle ----
EXTENDS Naturals

---- MODULE Ring ----
CONSTANTS Start, Succ
VARIABLE ph
RInit == ph = Start
RNext == ph' = Succ[ph]
RSpec == RInit /\ [][RNext]_ph /\ WF_ph(RNext)
====

CONSTANT Dwell
ASSUME Dwell \in 1..4

Phase == {"fill", "wash", "spin"}

Order ==
  [p \in Phase |-> CASE p = "fill" -> "wash"
                     [] p = "wash" -> "spin"
                     [] p = "spin" -> "fill"]

VARIABLES phase, timer
vars == <<phase, timer>>

Abs == INSTANCE Ring WITH Start <- "fill", Succ <- Order, ph <- phase

TypeOK ==
  /\ phase \in Phase
  /\ timer \in 0..Dwell

Init ==
  /\ phase = "fill"
  /\ timer = Dwell

Tick ==
  /\ timer > 0
  /\ timer' = timer - 1
  /\ UNCHANGED phase

Advance ==
  /\ timer = 0
  /\ phase' = Order[phase]
  /\ timer' \in 1..Dwell

Next == Tick \/ Advance

Fairness == WF_vars(Tick) /\ WF_vars(Advance)

Spec == Init /\ [][Next]_vars /\ Fairness

TickInvisible == [][Tick => UNCHANGED phase]_vars

WaitsForZero == [][phase' # phase => timer = 0]_vars

Refines == Abs!RSpec
====
