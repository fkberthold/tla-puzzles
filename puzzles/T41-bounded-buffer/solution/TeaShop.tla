---- MODULE TeaShop ----
EXTENDS Sequences, Integers, TLC

CAPACITY == 3

(*--algorithm TeaShop {
  variables counter = <<>>, served = 0;

  define {
    TypeOK ==
      /\ counter \in Seq({"B1", "B2"})
      /\ served \in 0..4
    BoundedCounter == Len(counter) <= CAPACITY
    Conservation == served + Len(counter) <= 4
    EventuallyServedAll == <>(served = 4)
  }

  fair process (brewer \in {"B1", "B2"})
  variables brewed = 0;
  {
    brewLoop:
      while (brewed < 2) {
        place:
          await Len(counter) < CAPACITY;
          counter := Append(counter, self);
          brewed := brewed + 1;
      };
  }

  fair process (server = "Server") {
    serveLoop:
      while (served < 4) {
        deliver:
          await counter /= <<>>;
          counter := Tail(counter);
          served := served + 1;
      };
  }
}

*)
\* BEGIN TRANSLATION (chksum(pcal) = "3acec4d0" /\ chksum(tla) = "3170853b")
VARIABLES pc, counter, served

(* define statement *)
TypeOK ==
  /\ counter \in Seq({"B1", "B2"})
  /\ served \in 0..4
BoundedCounter == Len(counter) <= CAPACITY
Conservation == served + Len(counter) <= 4
EventuallyServedAll == <>(served = 4)

VARIABLE brewed

vars == << pc, counter, served, brewed >>

ProcSet == ({"B1", "B2"}) \cup {"Server"}

Init == (* Global variables *)
        /\ counter = <<>>
        /\ served = 0
        (* Process brewer *)
        /\ brewed = [self \in {"B1", "B2"} |-> 0]
        /\ pc = [self \in ProcSet |-> CASE self \in {"B1", "B2"} -> "brewLoop"
                                        [] self = "Server" -> "serveLoop"]

brewLoop(self) == /\ pc[self] = "brewLoop"
                  /\ IF brewed[self] < 2
                        THEN /\ pc' = [pc EXCEPT ![self] = "place"]
                        ELSE /\ pc' = [pc EXCEPT ![self] = "Done"]
                  /\ UNCHANGED << counter, served, brewed >>

place(self) == /\ pc[self] = "place"
               /\ Len(counter) < CAPACITY
               /\ counter' = Append(counter, self)
               /\ brewed' = [brewed EXCEPT ![self] = brewed[self] + 1]
               /\ pc' = [pc EXCEPT ![self] = "brewLoop"]
               /\ UNCHANGED served

brewer(self) == brewLoop(self) \/ place(self)

serveLoop == /\ pc["Server"] = "serveLoop"
             /\ IF served < 4
                   THEN /\ pc' = [pc EXCEPT !["Server"] = "deliver"]
                   ELSE /\ pc' = [pc EXCEPT !["Server"] = "Done"]
             /\ UNCHANGED << counter, served, brewed >>

deliver == /\ pc["Server"] = "deliver"
           /\ counter /= <<>>
           /\ counter' = Tail(counter)
           /\ served' = served + 1
           /\ pc' = [pc EXCEPT !["Server"] = "serveLoop"]
           /\ UNCHANGED brewed

server == serveLoop \/ deliver

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == server
           \/ (\E self \in {"B1", "B2"}: brewer(self))
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ \A self \in {"B1", "B2"} : WF_vars(brewer(self))
        /\ WF_vars(server)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
================================
