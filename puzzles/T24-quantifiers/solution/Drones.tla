---- MODULE Drones ----
EXTENDS Integers, TLC

(*--algorithm Drones {
  variables
    battery = [d \in 1..4 |-> 10],
    state = [d \in 1..4 |-> "docked"],
    phase = 0;

  define {
    Drones == 1..4
    BatteryLevels == 1..10
    States == {"flying", "docked", "low"}

    TypeOK == \A d \in Drones : battery[d] \in BatteryLevels /\ state[d] \in States
    AnyDocked == \E d \in Drones : state[d] = "docked"
    LowConsistent == \A d \in Drones : (battery[d] <= 2 => state[d] = "low")
    AllSafe == \A d \in Drones : battery[d] >= 3
  }

  fair process (dispatcher = "Disp") {
    report:
      with (b \in [Drones -> 1..3]) {
        with (s \in [Drones -> States]) {
          battery := b;
          state := s;
        };
      };
      phase := phase + 1;
  }
}

*)
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
