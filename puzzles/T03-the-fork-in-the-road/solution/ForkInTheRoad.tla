---- MODULE ForkInTheRoad ----
EXTENDS TLC

(*--algorithm ForkInTheRoad {
  variables location = "fork", seated = FALSE;

  define {
    TypeOK ==
      /\ location \in {"fork", "lake", "summit"}
      /\ seated \in {TRUE, FALSE}
    AlwaysAtLake == location /= "summit"
    EventuallySits == <>(seated = TRUE)
  }

  fair process (hiker = "Hiker") {
    choose:
      either {
        location := "lake";
      } or {
        location := "summit";
      };
    sit:
      seated := TRUE;
  }
}

*)
\* BEGIN TRANSLATION (chksum(pcal) = "155240" /\ chksum(tla) = "a63e3a57")
VARIABLES pc, location, seated

(* define statement *)
TypeOK ==
  /\ location \in {"fork", "lake", "summit"}
  /\ seated \in {TRUE, FALSE}
AlwaysAtLake == location /= "summit"
EventuallySits == <>(seated = TRUE)


vars == << pc, location, seated >>

ProcSet == {"Hiker"}

Init == (* Global variables *)
        /\ location = "fork"
        /\ seated = FALSE
        /\ pc = [self \in ProcSet |-> "choose"]

choose == /\ pc["Hiker"] = "choose"
          /\ \/ /\ location' = "lake"
             \/ /\ location' = "summit"
          /\ pc' = [pc EXCEPT !["Hiker"] = "sit"]
          /\ UNCHANGED seated

sit == /\ pc["Hiker"] = "sit"
       /\ seated' = TRUE
       /\ pc' = [pc EXCEPT !["Hiker"] = "Done"]
       /\ UNCHANGED location

hiker == choose \/ sit

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == hiker
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(hiker)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 

================================
