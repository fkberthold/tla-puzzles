---- MODULE Pelican ----
\* Reference answer. The cycle and the dwell times are two CASE
\* expressions over the phase, and Advance names the next phase once
\* with LET so the dwell is looked up on the phase being entered.
EXTENDS Naturals

VARIABLES phase, timer, demand

vars == <<phase, timer, demand>>

Phases == {"go", "slow", "walk", "clear"}

Dwell(p) ==
  CASE p = "go"    -> 4
    [] p = "slow"  -> 3
    [] p = "walk"  -> 6
    [] p = "clear" -> 2

Succ(p) ==
  CASE p = "go"    -> "slow"
    [] p = "slow"  -> "walk"
    [] p = "walk"  -> "clear"
    [] p = "clear" -> "go"

TypeOK ==
  /\ phase \in Phases
  /\ timer \in 0..6
  /\ demand \in BOOLEAN

Init ==
  /\ phase = "go"
  /\ timer = 0
  /\ demand = FALSE

Press ==
  /\ ~demand
  /\ demand' = TRUE
  /\ UNCHANGED <<phase, timer>>

Tick ==
  /\ timer > 0
  /\ timer' = timer - 1
  /\ UNCHANGED <<phase, demand>>

Advance ==
  /\ timer = 0
  /\ phase = "go" => demand
  /\ LET next == Succ(phase) IN
       /\ phase' = next
       /\ timer' = Dwell(next)
       /\ demand' = IF next = "walk" THEN FALSE ELSE demand

Next == Press \/ Tick \/ Advance

Spec == Init /\ [][Next]_vars

TimerWithinDwell == timer <= Dwell(phase)

AmberOnlyOnDemand == phase = "slow" => demand
====
