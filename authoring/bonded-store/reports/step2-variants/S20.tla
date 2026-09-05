---------------------------- MODULE S20 ----------------------------
(***************************************************************************)
(* SEEDED VARIANT of authoring/bonded-store/reference/BondedStore.tla.      *)
(*                                                                          *)
(* release is unguarded, so any lot can be released                        *)
(* Targets: rule 3; must-be-true 2                                         *)
(*                                                                          *)
(* This is the reference's TRANSLATED text with the stated mutation and     *)
(* nothing else. The PlusCal source block is dropped on purpose: TLC reads  *)
(* the translation, and shipping an algorithm the translation no longer     *)
(* matches would be a second, unstated mutation.                            *)
(***************************************************************************)
CONSTANTS Lots
VARIABLES place, dutyPaid

Places == {"notEntered", "inStore", "released", "movedOn"}

Observe == [place |-> place, dutyPaid |-> dutyPaid]

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

vars == << place, dutyPaid >>

Init == /\ place = [l \in Lots |-> "notEntered"]
        /\ dutyPaid = [l \in Lots |-> FALSE]

Next == \E l \in Lots:
          \/ /\ place[l] = "notEntered"
             /\ place' = [place EXCEPT ![l] = "inStore"]
             /\ UNCHANGED dutyPaid
          \/ /\ place' = [place EXCEPT ![l] = "released"]
             /\ dutyPaid' = [dutyPaid EXCEPT ![l] = TRUE]
          \/ /\ place[l] = "inStore"
             /\ place' = [place EXCEPT ![l] = "movedOn"]
             /\ UNCHANGED dutyPaid

Spec == Init /\ [][Next]_vars
=============================================================================
