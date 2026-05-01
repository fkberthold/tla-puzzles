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
\* BEGIN TRANSLATION (chksum(pcal) = "73e8a961" /\ chksum(tla) = "5d5a103c")
VARIABLES pc, pending, served, slot

(* define statement *)
Clients == {"c1", "c2"}

TypeOK ==
  /\ pending \in [Clients -> BOOLEAN]
  /\ served  \in [Clients -> BOOLEAN]
  /\ slot    \in (Clients \cup {"empty"})


EveryRequestServed ==
  \A c \in Clients : (pending[c] = TRUE) ~> (served[c] = TRUE)


ServerStaysAvailable == []<>(slot = "empty")


vars == << pc, pending, served, slot >>

ProcSet == ({"c1", "c2"}) \cup {"Server"}

Init == (* Global variables *)
        /\ pending = [c \in {"c1", "c2"} |-> FALSE]
        /\ served = [c \in {"c1", "c2"} |-> FALSE]
        /\ slot = "empty"
        /\ pc = [self \in ProcSet |-> CASE self \in {"c1", "c2"} -> "cstart"
                                        [] self = "Server" -> "spick"]

cstart(self) == /\ pc[self] = "cstart"
                /\ pending[self] = FALSE /\ served[self] = FALSE
                /\ pending' = [pending EXCEPT ![self] = TRUE]
                /\ pc' = [pc EXCEPT ![self] = "cwait"]
                /\ UNCHANGED << served, slot >>

cwait(self) == /\ pc[self] = "cwait"
               /\ served[self] = TRUE
               /\ pc' = [pc EXCEPT ![self] = "Done"]
               /\ UNCHANGED << pending, served, slot >>

client(self) == cstart(self) \/ cwait(self)

spick == /\ pc["Server"] = "spick"
         /\ slot = "empty" /\ \E c \in Clients : pending[c]
         /\ \E c \in {x \in Clients : pending[x]}:
              slot' = c
         /\ pc' = [pc EXCEPT !["Server"] = "srespond"]
         /\ UNCHANGED << pending, served >>

srespond == /\ pc["Server"] = "srespond"
            /\ served' = [served EXCEPT ![slot] = TRUE]
            /\ pending' = [pending EXCEPT ![slot] = FALSE]
            /\ pc' = [pc EXCEPT !["Server"] = "sfree"]
            /\ slot' = slot

sfree == /\ pc["Server"] = "sfree"
         /\ slot' = "empty"
         /\ pc' = [pc EXCEPT !["Server"] = "spick"]
         /\ UNCHANGED << pending, served >>

server == spick \/ srespond \/ sfree

Next == server
           \/ (\E self \in {"c1", "c2"}: client(self))

Spec == /\ Init /\ [][Next]_vars
        /\ \A self \in {"c1", "c2"} : SF_vars(client(self))
        /\ SF_vars(server)

\* END TRANSLATION 
================================
