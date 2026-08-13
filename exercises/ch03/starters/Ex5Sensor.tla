---- MODULE Ex5Sensor ----
EXTENDS Integers, TLC

\* Untranslated. Run `pcal Ex5Sensor.tla` before you run TLC.

(*--algorithm sensor {
  variables
    temp \in 0..30,
    mode = "idle";

  {
    Sense:
      if (temp > 40) {
        Trip:
          mode := "alarm";
      } else {
        if (temp > 20) {
          mode := "cool";
        } else {
          mode := "hold";
        }
      };
    Settle:
      skip;
  }
}
*)
====
