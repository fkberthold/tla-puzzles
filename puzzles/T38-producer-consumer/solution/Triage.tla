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
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
