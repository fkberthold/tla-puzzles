---- MODULE Lottery ----
EXTENDS Integers, TLC

(*--algorithm Lottery {
  variables
    tickets = {1, 2, 3, 4},
    winner = 0,
    minValid = 0,
    phase = 0;

  define {
    Tickets == tickets
    AnyTicket == CHOOSE t \in Tickets : TRUE
    SmallestAtLeast2 ==
      CHOOSE t \in Tickets : t >= 2 /\ \A u \in Tickets : (u >= 2 => t <= u)

    TypeOK ==
      /\ winner \in Tickets \cup {0}
      /\ minValid \in Tickets \cup {0}
      /\ phase \in 0..2
    MinIs2 == phase = 2 => minValid = 2
    WinnerStable == phase >= 1 => winner = AnyTicket
  }

  fair process (operator = "Op") {
    announceWinner:
      winner := AnyTicket;
      phase := phase + 1;
    announceMinValid:
      minValid := SmallestAtLeast2;
      phase := phase + 1;
  }
}

*)
\* BEGIN TRANSLATION (chksum(pcal) = "200561ae" /\ chksum(tla) = "a27476cc")
VARIABLES tickets, winner, minValid, phase, pc

(* define statement *)
Tickets == tickets
AnyTicket == CHOOSE t \in Tickets : TRUE
SmallestAtLeast2 ==
  CHOOSE t \in Tickets : t >= 2 /\ \A u \in Tickets : (u >= 2 => t <= u)

TypeOK ==
  /\ winner \in Tickets \cup {0}
  /\ minValid \in Tickets \cup {0}
  /\ phase \in 0..2
MinIs2 == phase = 2 => minValid = 2
WinnerStable == phase >= 1 => winner = AnyTicket


vars == << tickets, winner, minValid, phase, pc >>

ProcSet == {"Op"}

Init == (* Global variables *)
        /\ tickets = {1, 2, 3, 4}
        /\ winner = 0
        /\ minValid = 0
        /\ phase = 0
        /\ pc = [self \in ProcSet |-> "announceWinner"]

announceWinner == /\ pc["Op"] = "announceWinner"
                  /\ winner' = AnyTicket
                  /\ phase' = phase + 1
                  /\ pc' = [pc EXCEPT !["Op"] = "announceMinValid"]
                  /\ UNCHANGED << tickets, minValid >>

announceMinValid == /\ pc["Op"] = "announceMinValid"
                    /\ minValid' = SmallestAtLeast2
                    /\ phase' = phase + 1
                    /\ pc' = [pc EXCEPT !["Op"] = "Done"]
                    /\ UNCHANGED << tickets, winner >>

operator == announceWinner \/ announceMinValid

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == operator
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(operator)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
================================
