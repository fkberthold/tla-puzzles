---- MODULE Atomic ----
\* Side A: read-and-increment fused into ONE label.
\* Two clients each increment a shared counter once.
\* Because read+write happens in one atomic step, no lost updates: final = 2.
EXTENDS Integers, TLC

(*--algorithm Atomic {
  variables counter = 0;

  define {
    TypeOK == counter \in 0..2
    \* The expected final-state property: after both clients are done, counter = 2.
    Correct == (\A self \in {"A", "B"} : pc[self] = "Done") => counter = 2
  }

  fair process (client \in {"A", "B"}) {
    bump:
      counter := counter + 1;
  }
}
*)
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
