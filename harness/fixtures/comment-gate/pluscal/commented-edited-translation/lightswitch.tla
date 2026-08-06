---- MODULE lightswitch ----
\* A three-flip light switch. AlwaysOff is deliberately false: it is violated
\* on the very first step, which is the whole teaching point.
EXTENDS TLC, Integers

(*--algorithm lightswitch {
variables
  \* the bulb, "on" or "off"
  light="off",
  \* how many flips have happened so far
  count=0;

define {
  (* TypeOk pins the shape of the state. AlwaysOff is the property under test
     and is expected to FAIL. *)
  TypeOk ==
    /\ light \in {"on", "off"}  
    /\ count \in 0..3
  AlwaysOff == light = "off"
}

(* The single process. There is no concurrency here -- the interest is
   entirely in the property, not in the interleaving. *)
process (lightswitch = "Lightswitch") {
  flip:
  while(count<3) {            \* three flips, then Done
    if(light = "off") {
      light := "on";
    } else {
      light := "off";
    };
    count := count + 1;
  }
}
}*)
\* BEGIN TRANSLATION (chksum(pcal) = "ada512f6" /\ chksum(tla) = "407a5c1b")
VARIABLES pc, light, count

(* define statement *)
TypeOk ==
  /\ light \in {"on", "off"}
  /\ count \in 0..3
AlwaysOff == light = "off"


vars == << pc, light, count >>

ProcSet == {"Lightswitch"}

Init == (* Global variables *)
        /\ light = "off"
        /\ count = 0
        /\ pc = [self \in ProcSet |-> "flip"]

flip == /\ pc["Lightswitch"] = "flip"
        /\ IF count<4
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

Spec == Init /\ [][Next]_vars

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 

\* Check with: tlc lightswitch.tla



==========================
