---- MODULE StrongFairness ----
\* Side C: strong fairness. The action eventually fires
\* if it is enabled INFINITELY OFTEN, even if it gets disabled in between.
\*
\* Two competing servers; only one can serve at a time. We require server S1
\* to serve eventually. With WEAK fairness alone, S1 could be repeatedly
\* disabled (when S2 is the chosen server) and stall forever. With STRONG
\* fairness on S1's serve, it must eventually fire whenever it's repeatedly
\* enabled.
EXTENDS Integers, TLC

(*--algorithm StrongFairness {
  variables servedBy = "none", round = 0;

  define {
    TypeOK ==
      /\ servedBy \in {"none", "S1", "S2"}
      /\ round \in 0..3
    S1EventuallyServes == <>(servedBy = "S1")
  }

  fair process (server1 = "S1") {
    s1: while (round < 3) {
          await servedBy = "none";
          servedBy := "S1";
          round := round + 1;
        };
  }

  fair process (server2 = "S2") {
    s2: while (round < 3) {
          await servedBy = "none";
          servedBy := "S2";
          round := round + 1;
        };
  }

  fair process (clock = "Clock") {
    tick: while (round < 3) {
            await servedBy # "none";
            servedBy := "none";
          };
  }
}
*)
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
