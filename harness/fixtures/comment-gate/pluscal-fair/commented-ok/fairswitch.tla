---- MODULE fairswitch ----
\* The fair form of the algorithm header: pcal emits WF_vars(Next) into the
\* translation, so Termination is actually provable here.
\*
\* Two hazards this fixture is deliberately clear of, both learned the hard way:
\* a bare backtick anywhere in a TLA+ comment is rejected by pcal's lexer, and
\* pcal binds to the FIRST algorithm header token in the file even when that
\* token sits inside a comment -- so prose must never spell it out.
EXTENDS TLC, Integers

(*--fair algorithm lightswitch {
variables
  \* the bulb, "on" or "off"
  light="off",
  count=0;              \* flips so far

define {
  (* AlwaysOff is expected to FAIL on the first step. *)
  TypeOk ==
    /\ light \in {"on", "off"}
    /\ count \in 0..3
  AlwaysOff == light = "off"
}

(* One process, no interleaving: the interest is entirely in fairness. *)
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

\* Check with: tlc fairswitch.tla

==========================
