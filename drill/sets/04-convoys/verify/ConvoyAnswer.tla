---- MODULE ConvoyAnswer ----
\* Reference answer. A convoy is the set of trucks in it, so the convoys on
\* the road are a set of sets. Merging two is the binary union. Everyone on
\* the road is the flattening of the whole collection, which is the other
\* union, and the one this item is built around.
EXTENDS Naturals, FiniteSets

CONSTANTS Trucks, MaxConvoy

VARIABLES atDepot, convoys

vars == <<atDepot, convoys>>

OnRoad == UNION convoys

TypeOK ==
  /\ atDepot \subseteq Trucks
  /\ convoys \subseteq SUBSET Trucks

Init ==
  /\ atDepot = Trucks
  /\ convoys = {}

Leave ==
  \E t \in atDepot :
    /\ atDepot' = atDepot \ {t}
    /\ convoys' = convoys \cup {{t}}

Merge ==
  \E c, d \in convoys :
    /\ c /= d
    /\ Cardinality(c \cup d) <= MaxConvoy
    /\ convoys' = (convoys \ {c, d}) \cup {c \cup d}
    /\ UNCHANGED atDepot

Arrive ==
  \E c \in convoys :
    /\ convoys' = convoys \ {c}
    /\ UNCHANGED atDepot

Next == Leave \/ Merge \/ Arrive

Spec == Init /\ [][Next]_vars

NowhereTwice ==
  /\ atDepot \cap OnRoad = {}
  /\ \A c, d \in convoys : c /= d => c \cap d = {}

NeverOversized == \A c \in convoys : Cardinality(c) <= MaxConvoy

NoEmptyConvoy == {} \notin convoys
====
