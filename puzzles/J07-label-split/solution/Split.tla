---- MODULE Split ----
\* Side B: read-and-increment SPLIT into two labels, with a temp.
\* Two clients each "read counter into local; write back local+1."
\* Because the two labels can interleave, the classic LOST UPDATE bug appears.
\* TLC will find a 5-state counterexample where final counter = 1, not 2.
EXTENDS Integers, TLC

(*--algorithm Split {
  variables counter = 0;

  define {
    TypeOK == counter \in 0..2
    Correct == (\A self \in {"A", "B"} : pc[self] = "Done") => counter = 2
  }

  fair process (client \in {"A", "B"})
    variables local = 0;
  {
    read:
      local := counter;
    write:
      counter := local + 1;
  }
}
*)
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
