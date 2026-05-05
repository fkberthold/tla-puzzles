---- MODULE Clinic ----
EXTENDS Integers, FiniteSets, TLC

Patients == {"P1", "P2", "P3"}

(*--algorithm Clinic {
  variables
    appointment = [p \in Patients |->
                     [doctor |-> 0, when |-> 0, status |-> "empty"]];

  define {
    Statuses == {"empty", "pending", "booked", "rejected"}

    TypeOK ==
      \A p \in Patients :
        /\ appointment[p].doctor \in 0..2
        /\ appointment[p].when \in 0..2
        /\ appointment[p].status \in Statuses

    NoContradiction ==
      \A p \in Patients :
        appointment[p].status /= "empty" =>
          /\ appointment[p].doctor \in 1..2
          /\ appointment[p].when \in 1..2

    EventuallyAllTerminal ==
      <>(\A p \in Patients :
            appointment[p].status \in {"booked", "rejected"})
  }

  fair process (patient \in Patients) {
    submit:
      with (d \in 1..2; t \in 1..2) {
        appointment[self] := [doctor |-> d, when |-> t, status |-> "pending"];
      };
    waitDecision:
      await appointment[self].status \in {"booked", "rejected"};
    leave:
      skip;
  }

  fair process (clerk = "Clerk") {
    clerkLoop:
      while (\E p \in Patients :
               appointment[p].status \in {"empty", "pending"}) {
        decide:
          await \E p \in Patients : appointment[p].status = "pending";
          with (p \in {q \in Patients : appointment[q].status = "pending"}) {
            either {
              appointment[p] := [appointment[p] EXCEPT !.status = "booked"];
            } or {
              appointment[p] := [appointment[p] EXCEPT !.status = "rejected"];
            };
          };
      };
  }
}

*)
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
