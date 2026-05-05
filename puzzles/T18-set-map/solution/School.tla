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
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
