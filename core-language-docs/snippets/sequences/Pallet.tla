---- MODULE Pallet ----
EXTENDS Integers, Sequences
VARIABLES stack, flat
vars == <<stack, flat>>

Layer == <<7, 8>>

Init == stack = <<>> /\ flat = <<>>
Add ==
  /\ Len(stack) < 2
  /\ stack' = Append(stack, Layer)
  /\ flat' = flat \o Layer
Next == Add \/ UNCHANGED vars
Spec == Init /\ [][Next]_vars

AppendNests == \A i \in DOMAIN stack : stack[i] = Layer
ConcatFlattens == \A i \in DOMAIN flat : flat[i] \in {7, 8}
LengthsTrack == Len(flat) = 2 * Len(stack)
SameLength == Len(stack) = Len(flat)
=======================
