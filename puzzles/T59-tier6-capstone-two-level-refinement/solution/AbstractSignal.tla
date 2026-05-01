---- MODULE AbstractSignal ----
EXTENDS Integers

CONSTANT MaxCycles
ASSUME MaxCycles \in Nat /\ MaxCycles >= 1

VARIABLES signal, cycles

vars == << signal, cycles >>

Init == signal = "stop" /\ cycles = 0

ToGo ==
  /\ signal = "stop"
  /\ signal' = "go"
  /\ cycles' = cycles

ToStop ==
  /\ signal = "go"
  /\ cycles < MaxCycles
  /\ signal' = "stop"
  /\ cycles' = cycles + 1

Next == ToGo \/ ToStop
Spec == Init /\ [][Next]_vars

TypeOK == signal \in {"go", "stop"} /\ cycles \in 0..MaxCycles

====
