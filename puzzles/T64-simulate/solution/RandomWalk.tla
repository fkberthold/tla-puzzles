---- MODULE RandomWalk ----
EXTENDS Integers, TLC

(*--algorithm RandomWalk {
  variables x = 0, y = 0, z = 0, steps = 0;

  define {
    TypeOK == x \in -200..200 /\ y \in -200..200 /\ z \in -200..200 /\ steps \in 0..200
    StaysReachable == x*x + y*y + z*z <= 200*200
  }

  fair process (walker = "Walker") {
    walk:
      while (steps < 200) {
        either { x := x + 1; }
        or     { x := x - 1; }
        or     { y := y + 1; }
        or     { y := y - 1; }
        or     { z := z + 1; }
        or     { z := z - 1; };
        steps := steps + 1;
      }
  }
}
*)
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
