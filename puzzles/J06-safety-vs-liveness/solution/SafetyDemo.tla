---- MODULE SafetyDemo ----
\* A toggle whose state is always either "on" or "off".
\* Demonstrates the SHAPE of a safety property: an INVARIANT.
\* Safety: "the state never escapes {on, off}".
\* Liveness: "eventually the toggle is on" — different shape, different cfg keyword.
EXTENDS Integers, TLC

(*--algorithm SafetyDemo {
  variables state = "off", flips = 0;

  define {
    \* Safety (invariant): state is always one of these two strings.
    StateOK == state \in {"on", "off"}

    \* Safety (invariant): flips never goes negative.
    FlipsNonNeg == flips >= 0

    \* Liveness (temporal property): eventually we reach "on".
    EventuallyOn == <>(state = "on")
  }

  fair process (toggler = "Toggler") {
    flip:
      while (flips < 2) {
        if (state = "off") { state := "on"; }
        else                { state := "off"; };
        flips := flips + 1;
      };
  }
}
*)
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
