---- MODULE Capstan ----

(*--algorithm capstan {
  variables pawlFore = TRUE, pawlAft = TRUE;

  process (port = "port") {
    PortFore:
      await pawlFore;
      pawlFore := FALSE;
    PortAft:
      await pawlAft;
      pawlAft := FALSE;
  }

  process (stbd = "stbd") {
    StbdAft:
      await pawlAft;
      pawlAft := FALSE;
    StbdFore:
      await pawlFore;
      pawlFore := FALSE;
  }
}*)
\* BEGIN TRANSLATION (chksum(pcal) = "a3c9c575" /\ chksum(tla) = "91537100")
VARIABLES pc, pawlFore, pawlAft

vars == << pc, pawlFore, pawlAft >>

ProcSet == {"port"} \cup {"stbd"}

Init == (* Global variables *)
        /\ pawlFore = TRUE
        /\ pawlAft = TRUE
        /\ pc = [self \in ProcSet |-> CASE self = "port" -> "PortFore"
                                        [] self = "stbd" -> "StbdAft"]

PortFore == /\ pc["port"] = "PortFore"
            /\ pawlFore
            /\ pawlFore' = FALSE
            /\ pc' = [pc EXCEPT !["port"] = "PortAft"]
            /\ UNCHANGED pawlAft

PortAft == /\ pc["port"] = "PortAft"
           /\ pawlAft
           /\ pawlAft' = FALSE
           /\ pc' = [pc EXCEPT !["port"] = "Done"]
           /\ UNCHANGED pawlFore

port == PortFore \/ PortAft

StbdAft == /\ pc["stbd"] = "StbdAft"
           /\ pawlAft
           /\ pawlAft' = FALSE
           /\ pc' = [pc EXCEPT !["stbd"] = "StbdFore"]
           /\ UNCHANGED pawlFore

StbdFore == /\ pc["stbd"] = "StbdFore"
            /\ pawlFore
            /\ pawlFore' = FALSE
            /\ pc' = [pc EXCEPT !["stbd"] = "Done"]
            /\ UNCHANGED pawlAft

stbd == StbdAft \/ StbdFore

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == port \/ stbd
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
========================
