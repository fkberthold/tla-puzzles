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
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
