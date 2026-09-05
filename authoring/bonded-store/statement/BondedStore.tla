---------------------------- MODULE BondedStore ----------------------------
CONSTANTS Lots

(*--algorithm bondedstore {
  variables
    place = [l \in Lots |-> "notEntered"],
    dutyPaid = [l \in Lots |-> FALSE];

  define {
    Places == {"notEntered", "inStore", "released", "movedOn"}

    Observe == [place |-> place, dutyPaid |-> dutyPaid]
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
\* BEGIN TRANSLATION (chksum(pcal) = "79ef0601" /\ chksum(tla) = "af4292c9")
VARIABLES place, dutyPaid

(* define statement *)
Places == {"notEntered", "inStore", "released", "movedOn"}

Observe == [place |-> place, dutyPaid |-> dutyPaid]


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
