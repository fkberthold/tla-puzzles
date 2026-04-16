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
\* BEGIN TRANSLATION (chksum(pcal) = "8aeb5252" /\ chksum(tla) = "27cadd16")
VARIABLES light, count, pc

(* define statement *)
TypeOK == light \in {"on", "off"} /\ count \in 0..3
AlwaysOff == light = "off"


vars == << light, count, pc >>

ProcSet == {"Person"}

Init == (* Global variables *)
        /\ light = "off"
        /\ count = 0
        /\ pc = [self \in ProcSet |-> "toggle"]

toggle == /\ pc["Person"] = "toggle"
          /\ IF count < 3
                THEN /\ IF light = "off"
                           THEN /\ light' = "on"
                           ELSE /\ light' = "off"
                     /\ count' = count + 1
                     /\ pc' = [pc EXCEPT !["Person"] = "toggle"]
                ELSE /\ pc' = [pc EXCEPT !["Person"] = "Done"]
                     /\ UNCHANGED << light, count >>

switcher == toggle

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == switcher
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(switcher)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 

================================
