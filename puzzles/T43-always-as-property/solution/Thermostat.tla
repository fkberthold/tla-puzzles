---- MODULE Thermostat ----
EXTENDS Integers, TLC

(*--algorithm Thermostat {
  variables temp = 70;

  define {
    TypeOK == temp \in 60..80
    InRange == temp \in 60..80
    AlwaysInRange == []InRange
  }

  fair process (board = "Board") {
    tick:
      while (TRUE) {
        either {
          if (temp < 80) {
            temp := temp + 1;
          };
        } or {
          if (temp > 60) {
            temp := temp - 1;
          };
        } or {
          skip;
        };
      }
  }
}

*)
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
