---- MODULE TicketMachine ----
EXTENDS Integers, TLC

(*--algorithm TicketMachine {
  variables tickets = 3, served = 0, sold = 0, status = "open";

  define {
    SoldOut == tickets = 0
    MaxCustomers == served = 5
    ShutDown == SoldOut \/ MaxCustomers

    TypeOK ==
      /\ tickets \in 0..3
      /\ served \in 0..5
      /\ sold \in 0..3
      /\ status \in {"open", "closed"}
    TicketConservation == sold + tickets = 3
    AllSold == status = "closed" => SoldOut
  }

  fair process (machine = "Machine") {
    serve:
      while (~ShutDown) {
        served := served + 1;
        either {
          \* Customer buys a ticket
          tickets := tickets - 1;
          sold := sold + 1;
        } or {
          \* Customer walks away
          skip;
        };
      };
    close:
      status := "closed";
  }
}

*)
\* BEGIN TRANSLATION (chksum(pcal) = "51ad9849" /\ chksum(tla) = "d91e2704")
VARIABLES tickets, served, sold, status, pc

(* define statement *)
SoldOut == tickets = 0
MaxCustomers == served = 5
ShutDown == SoldOut \/ MaxCustomers

TypeOK ==
  /\ tickets \in 0..3
  /\ served \in 0..5
  /\ sold \in 0..3
  /\ status \in {"open", "closed"}
TicketConservation == sold + tickets = 3
AllSold == status = "closed" => SoldOut


vars == << tickets, served, sold, status, pc >>

ProcSet == {"Machine"}

Init == (* Global variables *)
        /\ tickets = 3
        /\ served = 0
        /\ sold = 0
        /\ status = "open"
        /\ pc = [self \in ProcSet |-> "serve"]

serve == /\ pc["Machine"] = "serve"
         /\ IF ~ShutDown
               THEN /\ served' = served + 1
                    /\ \/ /\ tickets' = tickets - 1
                          /\ sold' = sold + 1
                       \/ /\ TRUE
                          /\ UNCHANGED <<tickets, sold>>
                    /\ pc' = [pc EXCEPT !["Machine"] = "serve"]
               ELSE /\ pc' = [pc EXCEPT !["Machine"] = "close"]
                    /\ UNCHANGED << tickets, served, sold >>
         /\ UNCHANGED status

close == /\ pc["Machine"] = "close"
         /\ status' = "closed"
         /\ pc' = [pc EXCEPT !["Machine"] = "Done"]
         /\ UNCHANGED << tickets, served, sold >>

machine == serve \/ close

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == machine
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(machine)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 

================================
