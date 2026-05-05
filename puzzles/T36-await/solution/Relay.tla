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
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
