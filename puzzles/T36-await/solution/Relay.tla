---- MODULE Relay ----
EXTENDS TLC

(*--algorithm Relay {
  variables handoffReady = FALSE, runnerBFinished = FALSE;

  define {
    TypeOK == handoffReady \in BOOLEAN /\ runnerBFinished \in BOOLEAN
    NoEarlyFinish == runnerBFinished => handoffReady
    EventuallyFinishes == <>(runnerBFinished = TRUE)
  }

  fair process (runnerA = "RunnerA") {
    handoff:
      handoffReady := TRUE;
  }

  fair process (runnerB = "RunnerB") {
    wait:
      await handoffReady;
    finish:
      runnerBFinished := TRUE;
  }
}

*)
\* BEGIN TRANSLATION (chksum(pcal) = "c73ec3d6" /\ chksum(tla) = "f5b65371")
VARIABLES pc, handoffReady, runnerBFinished

(* define statement *)
TypeOK == handoffReady \in BOOLEAN /\ runnerBFinished \in BOOLEAN
NoEarlyFinish == runnerBFinished => handoffReady
EventuallyFinishes == <>(runnerBFinished = TRUE)


vars == << pc, handoffReady, runnerBFinished >>

ProcSet == {"RunnerA"} \cup {"RunnerB"}

Init == (* Global variables *)
        /\ handoffReady = FALSE
        /\ runnerBFinished = FALSE
        /\ pc = [self \in ProcSet |-> CASE self = "RunnerA" -> "handoff"
                                        [] self = "RunnerB" -> "wait"]

handoff == /\ pc["RunnerA"] = "handoff"
           /\ handoffReady' = TRUE
           /\ pc' = [pc EXCEPT !["RunnerA"] = "Done"]
           /\ UNCHANGED runnerBFinished

runnerA == handoff

wait == /\ pc["RunnerB"] = "wait"
        /\ handoffReady
        /\ pc' = [pc EXCEPT !["RunnerB"] = "finish"]
        /\ UNCHANGED << handoffReady, runnerBFinished >>

finish == /\ pc["RunnerB"] = "finish"
          /\ runnerBFinished' = TRUE
          /\ pc' = [pc EXCEPT !["RunnerB"] = "Done"]
          /\ UNCHANGED handoffReady

runnerB == wait \/ finish

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == runnerA \/ runnerB
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(runnerA)
        /\ WF_vars(runnerB)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
================================
