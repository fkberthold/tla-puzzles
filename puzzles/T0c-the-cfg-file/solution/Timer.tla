---- MODULE Timer ----
EXTENDS Integers

CONSTANT MaxTicks

(*--algorithm Timer {
  variables ticks = 0;

  define {
    TypeOK == ticks \in 0..MaxTicks
  }

  fair process (clk = "Clock") {
    tick:
      while (ticks < MaxTicks) {
        ticks := ticks + 1;
      }
  }
}
*)
\* BEGIN TRANSLATION
\* END TRANSLATION
====
