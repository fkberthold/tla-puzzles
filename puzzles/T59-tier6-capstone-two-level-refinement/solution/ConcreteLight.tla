---- MODULE ConcreteLight ----
EXTENDS Integers

CONSTANT MaxCycles
ASSUME MaxCycles \in Nat /\ MaxCycles >= 1

\* color is the real state of the traffic light.
\* aux_cycles is an auxiliary variable that lets the refinement mapping
\* expose the cycle count to the abstract observer.
VARIABLES color, aux_cycles

vars == << color, aux_cycles >>

Init ==
  /\ color = "red"
  /\ aux_cycles = 0

\* Visible "stop" -> "go". Cycles unchanged.
RedToGreen ==
  /\ color = "red"
  /\ color' = "green"
  /\ UNCHANGED aux_cycles

\* Visible "go" -> "stop". Cycles increment AT THIS STEP because the
\* abstract couples the stop transition with the cycle increment.
GreenToYellow ==
  /\ color = "green"
  /\ aux_cycles < MaxCycles
  /\ color' = "yellow"
  /\ aux_cycles' = aux_cycles + 1

\* Internal step: yellow and red both map to "stop"; cycles unchanged.
\* Pure stutter on the abstract variables.
YellowToRed ==
  /\ color = "yellow"
  /\ color' = "red"
  /\ UNCHANGED aux_cycles

Next == RedToGreen \/ GreenToYellow \/ YellowToRed

Spec == Init /\ [][Next]_vars

TypeOK ==
  /\ color \in {"red", "green", "yellow"}
  /\ aux_cycles \in 0..MaxCycles

\* Refinement mapping:
\*   - The abstract signal is "go" iff the light is green.
\*   - The abstract cycle count is exactly aux_cycles.
L0 == INSTANCE AbstractSignal WITH
  signal <- IF color = "green" THEN "go" ELSE "stop",
  cycles <- aux_cycles

Refines == L0!Spec

====
