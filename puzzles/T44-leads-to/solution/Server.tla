---- MODULE Server ----
EXTENDS TLC

(*--algorithm Server {
  variables pending = FALSE, served = FALSE;

  define {
    TypeOK == pending \in BOOLEAN /\ served \in BOOLEAN
    RequestServed == pending ~> served
  }

  fair process (client = "Client") {
    cwork:
      while (TRUE) {
        either {
          \* Submit a fresh request.
          await ~pending /\ ~served;
          pending := TRUE;
        } or {
          \* Acknowledge a completed response.
          await served /\ ~pending;
          served := FALSE;
        };
      }
  }

  fair process (server = "Server") {
    swork:
      while (TRUE) {
        await pending;
        served := TRUE;
        pending := FALSE;
      }
  }
}

*)
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
