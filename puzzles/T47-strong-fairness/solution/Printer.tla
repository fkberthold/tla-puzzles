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
      while (TRUE) {
        either {
          await ~hasJob;
          hasJob := TRUE;     \* submit a new job
        } or {
          await hasJob;
          hasJob := FALSE;    \* cancel the pending job
        };
      }
  }

  fair+ process (printer = "Printer") {
    work:
      while (TRUE) {
        await hasJob;
        if (printed < 3) {
          printed := printed + 1;
        } else {
          printed := 0;       \* wrap: start counting again
        };
        hasJob := FALSE;
      }
  }
}

*)
\* BEGIN TRANSLATION (chksum(pcal) = "334b5d10" /\ chksum(tla) = "f7b5ec45")
VARIABLES hasJob, printed

(* define statement *)
TypeOK == hasJob \in BOOLEAN /\ printed \in 0..3
JobsServed == []<>(printed = 3)


vars == << hasJob, printed >>

ProcSet == {"User"} \cup {"Printer"}

Init == (* Global variables *)
        /\ hasJob = FALSE
        /\ printed = 0

user == /\ \/ /\ ~hasJob
              /\ hasJob' = TRUE
           \/ /\ hasJob
              /\ hasJob' = FALSE
        /\ UNCHANGED printed

printer == /\ hasJob
           /\ IF printed < 3
                 THEN /\ printed' = printed + 1
                 ELSE /\ printed' = 0
           /\ hasJob' = FALSE

Next == user \/ printer

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(user)
        /\ SF_vars(printer)

\* END TRANSLATION
================================
