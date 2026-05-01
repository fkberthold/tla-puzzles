---- MODULE Heartbeat ----
EXTENDS TLC

(*--algorithm Heartbeat {
  variables pulse = FALSE;

  define {
    TypeOK == pulse \in BOOLEAN
    BeatsForever == []<>(pulse = TRUE)
  }

  fair process (heart = "Heart") {
    beat:
      while (TRUE) {
        pulse := TRUE;
        rest:
          pulse := FALSE;
      }
  }
}

*)
\* BEGIN TRANSLATION (chksum(pcal) = "8e99bb" /\ chksum(tla) = "fc824b7e")
VARIABLES pulse, pc

(* define statement *)
TypeOK == pulse \in BOOLEAN
BeatsForever == []<>(pulse = TRUE)


vars == << pulse, pc >>

ProcSet == {"Heart"}

Init == (* Global variables *)
        /\ pulse = FALSE
        /\ pc = [self \in ProcSet |-> "beat"]

beat == /\ pc["Heart"] = "beat"
        /\ pulse' = TRUE
        /\ pc' = [pc EXCEPT !["Heart"] = "rest"]

rest == /\ pc["Heart"] = "rest"
        /\ pulse' = FALSE
        /\ pc' = [pc EXCEPT !["Heart"] = "beat"]

heart == beat \/ rest

Next == heart

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(heart)

\* END TRANSLATION 
================================
