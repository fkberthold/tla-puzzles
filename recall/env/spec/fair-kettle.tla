\* a kettle warming towards the boil while a clock ticks beside it. the kettle has three steps to go and then stops; the clock never stops.
---- MODULE Scaffold ----
EXTENDS Naturals, Integers, Sequences, FiniteSets, TLC
VARIABLES heat, tick
vars == <<heat, tick>>
Init == heat = 0 /\ tick = 0
Warm == heat < 3 /\ heat' = heat + 1 /\ tick' = tick
Tick == tick' = 1 - tick /\ heat' = heat
Next == Warm \/ Tick
Fair ==
__ANSWER__
Spec == Init /\ [][Next]_vars /\ Fair
Boils == <>(heat = 3)
====
