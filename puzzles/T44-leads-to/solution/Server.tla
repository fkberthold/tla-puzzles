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
\* BEGIN TRANSLATION (chksum(pcal) = "c80863d3" /\ chksum(tla) = "4a1b4822")
VARIABLES pending, served

(* define statement *)
TypeOK == pending \in BOOLEAN /\ served \in BOOLEAN
RequestServed == pending ~> served


vars == << pending, served >>

ProcSet == {"Client"} \cup {"Server"}

Init == (* Global variables *)
        /\ pending = FALSE
        /\ served = FALSE

client == \/ /\ ~pending /\ ~served
             /\ pending' = TRUE
             /\ UNCHANGED served
          \/ /\ served /\ ~pending
             /\ served' = FALSE
             /\ UNCHANGED pending

server == /\ pending
          /\ served' = TRUE
          /\ pending' = FALSE

Next == client \/ server

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(client)
        /\ WF_vars(server)

\* END TRANSLATION 
================================
