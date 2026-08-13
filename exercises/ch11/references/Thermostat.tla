---- MODULE Thermostat ----
\* Exercise 3 reference answer, which is also the shipped starter.
\*
\* A thermostat nudges its setpoint up or down one degree at a time. Every
\* setpoint it can reach is a legal setpoint, so the invariant has nothing to
\* say about how it got there. The action property does.
EXTENDS Integers

Low == 60
High == 64

(*--algorithm thermostat {
  variables
    setpoint = 60,
    mode = "idle";
  define {
    \* A state predicate. Checked with INVARIANT.
    InRange == setpoint \in Low..High

    \* An action. Checked with PROPERTY.
    MovesOneDegree == [][setpoint' - setpoint \in {-1, 1}]_setpoint
  }
  {
    Run:
      while (TRUE) {
        Adjust:
          either {
            await setpoint < High;
            setpoint := setpoint + 1;
          } or {
            await setpoint > Low;
            setpoint := setpoint - 1;
          };
          mode := "moving";
        Settle:
          mode := "idle";
      };
  }
}*)
\* BEGIN TRANSLATION (chksum(pcal) = "dfcca46d" /\ chksum(tla) = "c587689d")
VARIABLES pc, setpoint, mode

(* define statement *)
InRange == setpoint \in Low..High


MovesOneDegree == [][setpoint' - setpoint \in {-1, 1}]_setpoint


vars == << pc, setpoint, mode >>

Init == (* Global variables *)
        /\ setpoint = 60
        /\ mode = "idle"
        /\ pc = "Run"

Run == /\ pc = "Run"
       /\ pc' = "Adjust"
       /\ UNCHANGED << setpoint, mode >>

Adjust == /\ pc = "Adjust"
          /\ \/ /\ setpoint < High
                /\ setpoint' = setpoint + 1
             \/ /\ setpoint > Low
                /\ setpoint' = setpoint - 1
          /\ mode' = "moving"
          /\ pc' = "Settle"

Settle == /\ pc = "Settle"
          /\ mode' = "idle"
          /\ pc' = "Run"
          /\ UNCHANGED setpoint

Next == Run \/ Adjust \/ Settle

Spec == Init /\ [][Next]_vars

\* END TRANSLATION 
====
