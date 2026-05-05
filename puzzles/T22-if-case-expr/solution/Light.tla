---- MODULE Light ----
EXTENDS Integers, TLC

(*--algorithm Light {
  variables
    tick = 0,
    display = "red",
    goFlag = FALSE;

  define {
    Color(t) ==
      CASE t \in {0, 1}    -> "red"
        [] t = 2           -> "yellow"
        [] t \in {3, 4, 5} -> "green"
        [] OTHER           -> "off"
    IsGo(t) == IF Color(t) = "green" THEN TRUE ELSE FALSE

    TypeOK ==
      /\ tick \in 0..5
      /\ display \in {"red", "yellow", "green", "off"}
      /\ goFlag \in BOOLEAN
    DisplayMatches == display = Color(tick)
    GoMatches == goFlag = IsGo(tick)
  }

  fair process (controller = "Ctrl") {
    advance:
      while (tick < 5) {
        display := Color(tick + 1);
        goFlag := IsGo(tick + 1);
        tick := tick + 1;
      }
  }
}

*)
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
