---- MODULE Overlay ----
EXTENDS Naturals, TLC

CONSTANTS Key, Val, Depth
ASSUME Depth \in Nat

Layers == 1..Depth
Blank == [k \in {} |-> k]
Partial == UNION {[s -> Val] : s \in SUBSET Key}

VARIABLES layer, top
vars == <<layer, top>>

TypeOK ==
  /\ layer \in [Layers -> Partial]
  /\ top \in 0..Depth

Init ==
  /\ layer = [i \in Layers |-> Blank]
  /\ top = 0

\* The live layers folded into one function, bottom layer first.
Flat[i \in 0..Depth] ==
  IF i = 0 THEN Blank ELSE layer[i] @@ Flat[i - 1]

Effective == Flat[top]

Push == top < Depth /\ top' = top + 1 /\ UNCHANGED layer

Pop ==
  /\ top > 0
  /\ layer' = [layer EXCEPT ![top] = Blank]
  /\ top' = top - 1

Bind(i, k, v) ==
  /\ i \in 1..top
  /\ layer' = [layer EXCEPT ![i] = (k :> v) @@ @]
  /\ UNCHANGED top

Next ==
  \/ Push
  \/ Pop
  \/ \E i \in Layers, k \in Key, v \in Val : Bind(i, k, v)

Spec == Init /\ [][Next]_vars

Covered == DOMAIN Effective = UNION {DOMAIN layer[i] : i \in 1..top}

Topmost ==
  \A k \in DOMAIN Effective :
    \E i \in 1..top :
      /\ k \in DOMAIN layer[i]
      /\ layer[i][k] = Effective[k]
      /\ \A j \in (i + 1)..top : k \notin DOMAIN layer[j]

PushChangesNothing == [][top' > top => Effective' = Effective]_vars
====
