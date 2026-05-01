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
\* BEGIN TRANSLATION (chksum(pcal) = "936703db" /\ chksum(tla) = "26f1aa45")
VARIABLES pc, battery, state, phase

(* define statement *)
Drones == 1..4
BatteryLevels == 1..10
States == {"flying", "docked", "low"}

TypeOK == \A d \in Drones : battery[d] \in BatteryLevels /\ state[d] \in States
AnyDocked == \E d \in Drones : state[d] = "docked"
LowConsistent == \A d \in Drones : (battery[d] <= 2 => state[d] = "low")
AllSafe == \A d \in Drones : battery[d] >= 3


vars == << pc, battery, state, phase >>

ProcSet == {"Disp"}

Init == (* Global variables *)
        /\ battery = [d \in 1..4 |-> 10]
        /\ state = [d \in 1..4 |-> "docked"]
        /\ phase = 0
        /\ pc = [self \in ProcSet |-> "report"]

report == /\ pc["Disp"] = "report"
          /\ \E b \in [Drones -> 1..3]:
               \E s \in [Drones -> States]:
                 /\ battery' = b
                 /\ state' = s
          /\ phase' = phase + 1
          /\ pc' = [pc EXCEPT !["Disp"] = "Done"]

dispatcher == report

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == dispatcher
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(dispatcher)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
================================
