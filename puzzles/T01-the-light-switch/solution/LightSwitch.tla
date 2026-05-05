---- MODULE LightSwitch ----
EXTENDS Integers, TLC

(*--algorithm LightSwitch {
  variables light = "off", count = 0;

  define {
    TypeOK == light \in {"on", "off"} /\ count \in 0..3
    AlwaysOff == light = "off"  \* This WILL be violated!
  }

  fair process (switcher = "Person") {
    toggle:
      while (count < 3) {
        if (light = "off") {
          light := "on";
        } else {
          light := "off";
        };
        count := count + 1;
      }
  }
}

*)
\* BEGIN TRANSLATION
\* END TRANSLATION

================================
