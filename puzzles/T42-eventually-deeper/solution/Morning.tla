---- MODULE Morning ----
EXTENDS TLC

(*--algorithm Morning {
  variables alarmRang = FALSE, coffeeBrewed = FALSE, doorLocked = FALSE;

  define {
    TypeOK ==
      /\ alarmRang \in BOOLEAN
      /\ coffeeBrewed \in BOOLEAN
      /\ doorLocked \in BOOLEAN
    MorningComplete ==
      /\ <>(alarmRang = TRUE)
      /\ <>(coffeeBrewed = TRUE)
      /\ <>(doorLocked = TRUE)
  }

  fair process (routine = "Routine") {
    work:
      while (~alarmRang \/ ~coffeeBrewed \/ ~doorLocked) {
        either {
          alarmRang := TRUE;
        } or {
          coffeeBrewed := TRUE;
        } or {
          doorLocked := TRUE;
        };
      }
  }
}

*)
\* BEGIN TRANSLATION (chksum(pcal) = "16a0dd36" /\ chksum(tla) = "e89d25d")
VARIABLES alarmRang, coffeeBrewed, doorLocked, pc

(* define statement *)
TypeOK ==
  /\ alarmRang \in BOOLEAN
  /\ coffeeBrewed \in BOOLEAN
  /\ doorLocked \in BOOLEAN
MorningComplete ==
  /\ <>(alarmRang = TRUE)
  /\ <>(coffeeBrewed = TRUE)
  /\ <>(doorLocked = TRUE)


vars == << alarmRang, coffeeBrewed, doorLocked, pc >>

ProcSet == {"Routine"}

Init == (* Global variables *)
        /\ alarmRang = FALSE
        /\ coffeeBrewed = FALSE
        /\ doorLocked = FALSE
        /\ pc = [self \in ProcSet |-> "work"]

work == /\ pc["Routine"] = "work"
        /\ IF ~alarmRang \/ ~coffeeBrewed \/ ~doorLocked
              THEN /\ \/ /\ alarmRang' = TRUE
                         /\ UNCHANGED <<coffeeBrewed, doorLocked>>
                      \/ /\ coffeeBrewed' = TRUE
                         /\ UNCHANGED <<alarmRang, doorLocked>>
                      \/ /\ doorLocked' = TRUE
                         /\ UNCHANGED <<alarmRang, coffeeBrewed>>
                   /\ pc' = [pc EXCEPT !["Routine"] = "work"]
              ELSE /\ pc' = [pc EXCEPT !["Routine"] = "Done"]
                   /\ UNCHANGED << alarmRang, coffeeBrewed, doorLocked >>

routine == work

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == routine
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(routine)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
================================
