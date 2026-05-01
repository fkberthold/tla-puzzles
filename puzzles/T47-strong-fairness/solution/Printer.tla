---- MODULE Printer ----
EXTENDS Integers, TLC

(*--algorithm Printer {
  variables hasJob = FALSE, printed = 0;

  define {
    TypeOK == hasJob \in BOOLEAN /\ printed \in 0..3
    JobsServed == []<>(printed = 3)
  }

  fair process (user = "User") {
    submit:
      while (printed < 3) {
        await ~hasJob;
        hasJob := TRUE;
      }
  }

  fair+ process (printer = "Printer") {
    work:
      while (TRUE) {
        await hasJob;
        printed := printed + 1;
        hasJob := FALSE;
      }
  }
}

*)
\* BEGIN TRANSLATION (chksum(pcal) = "ea2f1de9" /\ chksum(tla) = "ad7498cf")
VARIABLES pc, hasJob, printed

(* define statement *)
TypeOK == hasJob \in BOOLEAN /\ printed \in 0..3
JobsServed == []<>(printed = 3)


vars == << pc, hasJob, printed >>

ProcSet == {"User"} \cup {"Printer"}

Init == (* Global variables *)
        /\ hasJob = FALSE
        /\ printed = 0
        /\ pc = [self \in ProcSet |-> CASE self = "User" -> "submit"
                                        [] self = "Printer" -> "work"]

submit == /\ pc["User"] = "submit"
          /\ IF printed < 3
                THEN /\ ~hasJob
                     /\ hasJob' = TRUE
                     /\ pc' = [pc EXCEPT !["User"] = "submit"]
                ELSE /\ pc' = [pc EXCEPT !["User"] = "Done"]
                     /\ UNCHANGED hasJob
          /\ UNCHANGED printed

user == submit

work == /\ pc["Printer"] = "work"
        /\ hasJob
        /\ printed' = printed + 1
        /\ hasJob' = FALSE
        /\ pc' = [pc EXCEPT !["Printer"] = "work"]

printer == work

Next == user \/ printer

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(user)
        /\ SF_vars(printer)

\* END TRANSLATION 
================================
