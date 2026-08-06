---- MODULE fairswitch ----
EXTENDS TLC, Integers

(*--fair algorithm lightswitch {
variables
  light="off",
  count=0;

define {
  TypeOk ==
    /\ light \in {"on", "off"}  
    /\ count \in 0..3
  AlwaysOff == light = "off"
}

process (lightswitch = "Lightswitch") {
  flip:
  while(count<3) {
    if(light = "off") {
      light := "on";
    } else {
      light := "off";
    };
    count := count + 1;
  }
}
}*)
\* BEGIN TRANSLATION (chksum(pcal) = "ab8a72cc" /\ chksum(tla) = "7c235648")
VARIABLES light, count, pc

(* define statement *)
TypeOk ==
  /\ light \in {"on", "off"}
  /\ count \in 0..3
AlwaysOff == light = "off"


vars == << light, count, pc >>

ProcSet == {"Lightswitch"}

Init == (* Global variables *)
        /\ light = "off"
        /\ count = 0
        /\ pc = [self \in ProcSet |-> "flip"]

flip == /\ pc["Lightswitch"] = "flip"
        /\ IF count<3
              THEN /\ IF light = "off"
                         THEN /\ light' = "on"
                         ELSE /\ light' = "off"
                   /\ count' = count + 1
                   /\ pc' = [pc EXCEPT !["Lightswitch"] = "flip"]
              ELSE /\ pc' = [pc EXCEPT !["Lightswitch"] = "Done"]
                   /\ UNCHANGED << light, count >>

lightswitch == flip

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == lightswitch
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(Next)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 



==========================
