---- MODULE School ----
EXTENDS Integers, TLC

(*--algorithm School {
  variables
    level = [s \in {"sam", "tess", "uri", "val"} |->
              IF s = "sam" THEN 9
              ELSE IF s = "tess" THEN 11
              ELSE IF s = "uri" THEN 9
              ELSE 12],
    gradesPresent = {},
    phase = 0;

  define {
    Students == DOMAIN level

    TypeOK ==
      /\ Students = {"sam", "tess", "uri", "val"}
      /\ gradesPresent \subseteq 9..12
      /\ phase \in 0..2
    EndsCorrect == phase = 2 => gradesPresent = {9, 11, 12}
    EveryGradeIsAStudentsGrade ==
      \A g \in gradesPresent : \E s \in Students : level[s] = g
  }

  fair process (principal = "Princ") {
    derive:
      gradesPresent := {level[s] : s \in DOMAIN level};
      phase := phase + 1;
    finish:
      phase := phase + 1;
  }
}

*)
\* BEGIN TRANSLATION (chksum(pcal) = "c14fc8c0" /\ chksum(tla) = "8443649")
VARIABLES level, gradesPresent, phase, pc

(* define statement *)
Students == DOMAIN level

TypeOK ==
  /\ Students = {"sam", "tess", "uri", "val"}
  /\ gradesPresent \subseteq 9..12
  /\ phase \in 0..2
EndsCorrect == phase = 2 => gradesPresent = {9, 11, 12}
EveryGradeIsAStudentsGrade ==
  \A g \in gradesPresent : \E s \in Students : level[s] = g


vars == << level, gradesPresent, phase, pc >>

ProcSet == {"Princ"}

Init == (* Global variables *)
        /\ level = [s \in {"sam", "tess", "uri", "val"} |->
                     IF s = "sam" THEN 9
                     ELSE IF s = "tess" THEN 11
                     ELSE IF s = "uri" THEN 9
                     ELSE 12]
        /\ gradesPresent = {}
        /\ phase = 0
        /\ pc = [self \in ProcSet |-> "derive"]

derive == /\ pc["Princ"] = "derive"
          /\ gradesPresent' = {level[s] : s \in DOMAIN level}
          /\ phase' = phase + 1
          /\ pc' = [pc EXCEPT !["Princ"] = "finish"]
          /\ level' = level

finish == /\ pc["Princ"] = "finish"
          /\ phase' = phase + 1
          /\ pc' = [pc EXCEPT !["Princ"] = "Done"]
          /\ UNCHANGED << level, gradesPresent >>

principal == derive \/ finish

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == principal
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(principal)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
================================
