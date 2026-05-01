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
\* BEGIN TRANSLATION (chksum(pcal) = "a7557061" /\ chksum(tla) = "ec1a8f63")
VARIABLES published, received

(* define statement *)
TypeOK == published \in BOOLEAN /\ received \in BOOLEAN
PublishedEventuallyReceived == published ~> received


vars == << published, received >>

ProcSet == {"Publisher"} \cup {"Subscriber"}

Init == (* Global variables *)
        /\ published = FALSE
        /\ received = FALSE

publisher == \/ /\ ~published /\ ~received
                /\ published' = TRUE
                /\ UNCHANGED received
             \/ /\ ~published /\ received
                /\ received' = FALSE
                /\ UNCHANGED published

subscriber == /\ published
              /\ received' = TRUE
              /\ published' = FALSE

Next == publisher \/ subscriber

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(publisher)

\* END TRANSLATION
================================
