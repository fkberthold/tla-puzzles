---- MODULE BellTower ----
\* Exercise 5 starter. This one is complete. Read it, predict, then run.
\*
\* Two ringers each pull a rope `Quota` times. `chimes` counts every pull by
\* anybody. `left` is each ringer's own countdown, and it is a process-local
\* variable, so each ringer has its own.
\*
\* Note where `TallyMatches` sits. It is the last line before the `====`, below
\* where `pcal` will put the translation. `RightTotal` sits in the `define`
\* block instead. The exercise is about why they cannot swap places.
EXTENDS Integers, FiniteSets

Ringers == 1..2
Quota == 2

(*--algorithm belltower {
  variables chimes = 0;

  define {
    AllRung == \A r \in Ringers : pc[r] = "Done"
    RightTotal == AllRung => chimes = Quota * Cardinality(Ringers)
  }

  process (ringer \in Ringers)
    variables left = Quota;
  {
    Pull:
      while (left > 0) {
        chimes := chimes + 1;
        left := left - 1;
      };
  }
}
*)

\* The two ringers are written out by hand here. Adding up one entry per
\* element of a set needs a recursive operator, which this course has not
\* reached yet.
TallyMatches == chimes + left[1] + left[2] = Quota * Cardinality(Ringers)
====
