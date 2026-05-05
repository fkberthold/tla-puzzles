---- MODULE Broadcast ----
EXTENDS TLC

(*--algorithm Broadcast {
  variables published = FALSE, received = FALSE;

  define {
    TypeOK == published \in BOOLEAN /\ received \in BOOLEAN
    PublishedEventuallyReceived == published ~> received
  }

  fair process (publisher = "Publisher") {
    pub:
      while (TRUE) {
        either {
          \* Publish a notification.
          await ~published /\ ~received;
          published := TRUE;
        } or {
          \* Reset after being received.
          await ~published /\ received;
          received := FALSE;
        };
      }
  }

  process (subscriber = "Subscriber") {        \* BUG: missing `fair`!
    sub:
      while (TRUE) {
        await published;
        received := TRUE;
        published := FALSE;
      }
  }
}

*)
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
