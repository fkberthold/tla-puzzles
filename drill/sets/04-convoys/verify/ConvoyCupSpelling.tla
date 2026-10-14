---- MODULE ConvoyCupSpelling ----
\* Wrong neighbor. The binary union symbol used as if it flattened a
\* collection. It takes two operands, so this doesn't parse, and the parser
\* is the one reporting it rather than TLC.
EXTENDS Naturals, FiniteSets

CONSTANTS Trucks, MaxConvoy

VARIABLES atDepot, convoys

vars == <<atDepot, convoys>>

OnRoad == \cup convoys

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
