---------------------------- MODULE S24 ----------------------------
(***************************************************************************)
(* SEEDED VARIANT of authoring/bonded-store/reference/BondedStore.tla.      *)
(*                                                                          *)
(* duty derived from place, the representation the author refused          *)
(* Targets: the ALTERNATIVES.md claim about a derived duty                 *)
(*                                                                          *)
(* This is the reference's TRANSLATED text with the stated mutation and     *)
(* nothing else. The PlusCal source block is dropped on purpose: TLC reads  *)
(* the translation, and shipping an algorithm the translation no longer     *)
(* matches would be a second, unstated mutation.                            *)
(***************************************************************************)
CONSTANTS Lots
VARIABLES place

Places == {"notEntered", "inStore", "released", "movedOn"}

Observe == [place |-> place,
            dutyPaid |-> [l \in Lots |-> place[l] = "released"]]

TypeOK ==
    /\ Observe.place \in [Lots -> Places]
    /\ Observe.dutyPaid \in [Lots -> BOOLEAN]

DutyMatchesPlace ==
    \A l \in Lots :
        Observe.dutyPaid[l] <=> Observe.place[l] = "released"

MovementIsLawful ==
    [][\A l \in Lots :
          /\ ((Observe.place[l] = "notEntered"
                   /\ Observe'.place[l] # "notEntered")
                 => Observe'.place[l] = "inStore")
          /\ ((Observe.place[l] = "inStore"
                   /\ Observe'.place[l] # "inStore")
                 => Observe'.place[l] \in {"released", "movedOn"})]_Observe

LeavingIsFinal ==
    [][\A l \in Lots :
          Observe.place[l] \in {"released", "movedOn"} =>
              /\ Observe'.place[l] = Observe.place[l]
              /\ Observe'.dutyPaid[l] = Observe.dutyPaid[l]]_Observe

vars == << place >>

Init == place = [l \in Lots |-> "notEntered"]

Next == \E l \in Lots:
          \/ /\ place[l] = "notEntered"
             /\ place' = [place EXCEPT ![l] = "inStore"]
          \/ /\ place[l] = "inStore"
             /\ place' = [place EXCEPT ![l] = "released"]
          \/ /\ place[l] = "inStore"
             /\ place' = [place EXCEPT ![l] = "movedOn"]

Spec == Init /\ [][Next]_vars
=============================================================================
