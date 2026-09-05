---------------------------- MODULE BondedStore ----------------------------
CONSTANTS Lots

(*--algorithm bondedstore {
  variables
    place = [l \in Lots |-> "notEntered"],
    dutyPaid = [l \in Lots |-> FALSE];

  define {
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
  }

  {
    Keep:
      while (TRUE) {
        with (l \in Lots) {
          either {
            await place[l] = "notEntered";
            place[l] := "inStore";
          } or {
            await place[l] = "inStore";
            place[l] := "released";
            dutyPaid[l] := TRUE;
          } or {
            await place[l] = "inStore";
            place[l] := "movedOn";
          };
        };
      };
  }
}*)
\* BEGIN TRANSLATION (chksum(pcal) = "24038cab" /\ chksum(tla) = "7a766261")
VARIABLES place, dutyPaid

(* define statement *)
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

Init == (* Global variables *)
        /\ place = [l \in Lots |-> "notEntered"]
        /\ dutyPaid = [l \in Lots |-> FALSE]

Next == \E l \in Lots:
          \/ /\ place[l] = "notEntered"
             /\ place' = [place EXCEPT ![l] = "inStore"]
             /\ UNCHANGED dutyPaid
          \/ /\ place[l] = "inStore"
             /\ place' = [place EXCEPT ![l] = "released"]
             /\ dutyPaid' = [dutyPaid EXCEPT ![l] = TRUE]
          \/ /\ place[l] = "inStore"
             /\ place' = [place EXCEPT ![l] = "movedOn"]
             /\ UNCHANGED dutyPaid

Spec == Init /\ [][Next]_vars

\* END TRANSLATION 

=============================================================================
