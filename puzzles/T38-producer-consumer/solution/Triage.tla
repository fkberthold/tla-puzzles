---- MODULE Triage ----
EXTENDS Sequences, Integers, TLC

(*--algorithm Triage {
  variables queue = <<>>, treated = 0;

  define {
    TypeOK ==
      /\ queue \in Seq({"P1", "P2", "P3"})
      /\ treated \in 0..3
    NoUnderflow == treated <= 3
    BoundedQueue == Len(queue) <= 3
    Conservation == treated + Len(queue) <= 3
  }

  fair process (nurse = "Nurse")
  variables i = 1;
  {
    intakeLoop:
      while (i <= 3) {
        intake:
          queue := Append(queue, "P" \o ToString(i));
          i := i + 1;
      };
  }

  fair process (doctor = "Doctor") {
    treatLoop:
      while (treated < 3) {
        treat:
          await queue /= <<>>;
          queue := Tail(queue);
          treated := treated + 1;
      };
  }
}

*)
\* BEGIN TRANSLATION (chksum(pcal) = "64223d9e" /\ chksum(tla) = "3e4b7c0e")
VARIABLES queue, treated, pc

(* define statement *)
TypeOK ==
  /\ queue \in Seq({"P1", "P2", "P3"})
  /\ treated \in 0..3
NoUnderflow == treated <= 3
BoundedQueue == Len(queue) <= 3
Conservation == treated + Len(queue) <= 3

VARIABLE i

vars == << queue, treated, pc, i >>

ProcSet == {"Nurse"} \cup {"Doctor"}

Init == (* Global variables *)
        /\ queue = <<>>
        /\ treated = 0
        (* Process nurse *)
        /\ i = 1
        /\ pc = [self \in ProcSet |-> CASE self = "Nurse" -> "intakeLoop"
                                        [] self = "Doctor" -> "treatLoop"]

intakeLoop == /\ pc["Nurse"] = "intakeLoop"
              /\ IF i <= 3
                    THEN /\ pc' = [pc EXCEPT !["Nurse"] = "intake"]
                    ELSE /\ pc' = [pc EXCEPT !["Nurse"] = "Done"]
              /\ UNCHANGED << queue, treated, i >>

intake == /\ pc["Nurse"] = "intake"
          /\ queue' = Append(queue, "P" \o ToString(i))
          /\ i' = i + 1
          /\ pc' = [pc EXCEPT !["Nurse"] = "intakeLoop"]
          /\ UNCHANGED treated

nurse == intakeLoop \/ intake

treatLoop == /\ pc["Doctor"] = "treatLoop"
             /\ IF treated < 3
                   THEN /\ pc' = [pc EXCEPT !["Doctor"] = "treat"]
                   ELSE /\ pc' = [pc EXCEPT !["Doctor"] = "Done"]
             /\ UNCHANGED << queue, treated, i >>

treat == /\ pc["Doctor"] = "treat"
         /\ queue /= <<>>
         /\ queue' = Tail(queue)
         /\ treated' = treated + 1
         /\ pc' = [pc EXCEPT !["Doctor"] = "treatLoop"]
         /\ i' = i

doctor == treatLoop \/ treat

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == nurse \/ doctor
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(nurse)
        /\ WF_vars(doctor)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
================================
