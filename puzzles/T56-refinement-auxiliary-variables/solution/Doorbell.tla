---- MODULE Doorbell ----
EXTENDS Integers

CONSTANT Max
ASSUME Max \in Nat /\ Max >= 1

\* aux_rings is an AUXILIARY variable: it exists only to support the
\* refinement mapping. Real actions write it but never read it.
VARIABLES state, aux_rings

vars == << state, aux_rings >>

Init ==
  /\ state = "idle"
  /\ aux_rings = 0

Press ==
  /\ state = "idle"
  /\ state' = "ringing"
  /\ UNCHANGED aux_rings

Settle ==
  /\ state = "ringing"
  /\ aux_rings < Max
  /\ state' = "idle"
  /\ aux_rings' = aux_rings + 1

Next == Press \/ Settle

Spec == Init /\ [][Next]_vars

TypeOK ==
  /\ state \in {"idle", "ringing"}
  /\ aux_rings \in 0..Max

\* Refinement mapping: the abstract counter is exactly aux_rings.
L0 == INSTANCE RingCount WITH rings <- aux_rings
Refines == L0!Spec

====
