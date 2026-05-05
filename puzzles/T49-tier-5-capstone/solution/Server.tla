---- MODULE Server ----
EXTENDS TLC

(*--algorithm Server {
  variables
    pending = [c \in {"c1", "c2"} |-> FALSE],
    served  = [c \in {"c1", "c2"} |-> FALSE],
    slot    = "empty";

  define {
    Clients == {"c1", "c2"}

    TypeOK ==
      /\ pending \in [Clients -> BOOLEAN]
      /\ served  \in [Clients -> BOOLEAN]
      /\ slot    \in (Clients \cup {"empty"})

    \* Every pending request leads to a served response.
    EveryRequestServed ==
      \A c \in Clients : (pending[c] = TRUE) ~> (served[c] = TRUE)

    \* Server returns to idle infinitely often.
    ServerStaysAvailable == []<>(slot = "empty")
  }

  \* Each client requests exactly once and waits for the response.
  fair+ process (client \in {"c1", "c2"}) {
    cstart:
      await pending[self] = FALSE /\ served[self] = FALSE;
      pending[self] := TRUE;
    cwait:
      await served[self] = TRUE;
  }

  \* Server picks any pending client, marks served, frees the slot.
  fair+ process (server = "Server") {
    spick:
      while (TRUE) {
        await slot = "empty" /\ \E c \in Clients : pending[c];
        with (c \in {x \in Clients : pending[x]}) {
          slot := c;
        };
      srespond:
        served[slot] := TRUE;
        pending[slot] := FALSE;
      sfree:
        slot := "empty";
      }
  }
}

*)
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
