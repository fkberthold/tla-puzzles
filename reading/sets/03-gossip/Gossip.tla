---- MODULE Gossip ----
EXTENDS Naturals, FiniteSets

CONSTANT N
ASSUME N \in 2..6

Phone == 1..N
Src == 1

\* A link is the unordered pair of its ends, so on a two-phone ring the two
\* links are one link. The count below is what notices.
Edge == {{p, (p % N) + 1} : p \in Phone}
ASSUME Cardinality(Edge) = N

VARIABLES link, ever, heard
vars == <<link, ever, heard>>

TypeOK ==
  /\ link \in SUBSET Edge
  /\ ever \in SUBSET Edge
  /\ heard \subseteq Phone

Init == link = {} /\ ever = {} /\ heard = {Src}

\* The least set holding S and closed under every link that has ever been
\* up. A round that adds nothing stops the recursion.
RECURSIVE Reach(_)
Reach(S) ==
  LET out == {q \in Phone : \E p \in S : {p, q} \in ever}
  IN  IF out \subseteq S THEN S ELSE Reach(S \cup out)

Up(e) ==
  /\ e \notin link
  /\ link' = link \cup {e}
  /\ ever' = ever \cup {e}
  /\ UNCHANGED heard

Down(e) ==
  /\ e \in link
  /\ link' = link \ {e}
  /\ UNCHANGED <<ever, heard>>

Tell(e) ==
  /\ e \in link
  /\ \E p \in e : p \in heard
  /\ heard' = heard \cup e
  /\ UNCHANGED <<link, ever>>

Next == \E e \in Edge : Up(e) \/ Down(e) \/ Tell(e)
Spec == Init /\ [][Next]_vars

Sound == heard \subseteq Reach({Src})
Closed(S) == \A p \in S : \A q \in Phone : {p, q} \in ever => q \in S
Tightest == \A S \in SUBSET Phone :
              (Src \in S /\ Closed(S)) => Reach({Src}) \subseteq S
AcrossALink ==
  [][\A q \in heard' \ heard : \E p \in heard : {p, q} \in link]_vars
Spreading == [][heard \subseteq heard']_vars
====
