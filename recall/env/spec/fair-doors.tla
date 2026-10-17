\* two doors of an airlock, each of which opens once, and a buzzer that can sound back and forth for ever without either door moving.
---- MODULE Scaffold ----
EXTENDS Naturals, Integers, Sequences, FiniteSets, TLC
VARIABLES inner, outer, buzz
vars == <<inner, outer, buzz>>
Init == inner = 0 /\ outer = 0 /\ buzz = 0
OpenInner == inner = 0 /\ inner' = 1 /\ outer' = outer /\ buzz' = buzz
OpenOuter == outer = 0 /\ outer' = 1 /\ inner' = inner /\ buzz' = buzz
Buzz == buzz' = 1 - buzz /\ inner' = inner /\ outer' = outer
Next == OpenInner \/ OpenOuter \/ Buzz
Fair ==
__ANSWER__
Spec == Init /\ [][Next]_vars /\ Fair
Clear == <>(inner = 1 /\ outer = 1)
====
