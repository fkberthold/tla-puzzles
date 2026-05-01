---- MODULE Faucet ----
EXTENDS TLC

(*--algorithm Faucet {
  variables dropFell = FALSE;

  define {
    TypeOK == dropFell \in BOOLEAN
    EventuallyDrips == <>(dropFell = TRUE)
  }

  fair process (faucet = "Faucet") {
    flow:
      either {
        \* drip slowly
        dropFell := TRUE;
      } or {
        \* run for a moment
        dropFell := TRUE;
      };
  }
}

*)
\* BEGIN TRANSLATION (chksum(pcal) = "ebfb1187" /\ chksum(tla) = "d8f9fa7c")
VARIABLES pc, dropFell

(* define statement *)
TypeOK == dropFell \in BOOLEAN
EventuallyDrips == <>(dropFell = TRUE)


vars == << pc, dropFell >>

ProcSet == {"Faucet"}

Init == (* Global variables *)
        /\ dropFell = FALSE
        /\ pc = [self \in ProcSet |-> "flow"]

flow == /\ pc["Faucet"] = "flow"
        /\ \/ /\ dropFell' = TRUE
           \/ /\ dropFell' = TRUE
        /\ pc' = [pc EXCEPT !["Faucet"] = "Done"]

faucet == flow

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == faucet
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(faucet)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
================================
