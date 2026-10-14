---- MODULE ConvoyMergeFlat ----
\* Wrong neighbor. Merge unions the two convoys into the collection
\* instead of adding their union as one element. The braces around the
\* joined set are the whole difference, and without them the trucks
\* themselves land in the set of convoys.
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
    /\ convoys' = (convoys \ {c, d}) \cup c \cup d
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
