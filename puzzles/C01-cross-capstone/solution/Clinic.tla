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
\* BEGIN TRANSLATION (chksum(pcal) = "ed1eb40" /\ chksum(tla) = "6af5ca05")
VARIABLES appointment, pc

(* define statement *)
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


vars == << appointment, pc >>

ProcSet == (Patients) \cup {"Clerk"}

Init == (* Global variables *)
        /\ appointment = [p \in Patients |->
                            [doctor |-> 0, when |-> 0, status |-> "empty"]]
        /\ pc = [self \in ProcSet |-> CASE self \in Patients -> "submit"
                                        [] self = "Clerk" -> "clerkLoop"]

submit(self) == /\ pc[self] = "submit"
                /\ \E d \in 1..2:
                     \E t \in 1..2:
                       appointment' = [appointment EXCEPT ![self] = [doctor |-> d, when |-> t, status |-> "pending"]]
                /\ pc' = [pc EXCEPT ![self] = "waitDecision"]

waitDecision(self) == /\ pc[self] = "waitDecision"
                      /\ appointment[self].status \in {"booked", "rejected"}
                      /\ pc' = [pc EXCEPT ![self] = "leave"]
                      /\ UNCHANGED appointment

leave(self) == /\ pc[self] = "leave"
               /\ TRUE
               /\ pc' = [pc EXCEPT ![self] = "Done"]
               /\ UNCHANGED appointment

patient(self) == submit(self) \/ waitDecision(self) \/ leave(self)

clerkLoop == /\ pc["Clerk"] = "clerkLoop"
             /\ IF \E p \in Patients :
                     appointment[p].status \in {"empty", "pending"}
                   THEN /\ pc' = [pc EXCEPT !["Clerk"] = "decide"]
                   ELSE /\ pc' = [pc EXCEPT !["Clerk"] = "Done"]
             /\ UNCHANGED appointment

decide == /\ pc["Clerk"] = "decide"
          /\ \E p \in Patients : appointment[p].status = "pending"
          /\ \E p \in {q \in Patients : appointment[q].status = "pending"}:
               \/ /\ appointment' = [appointment EXCEPT ![p] = [appointment[p] EXCEPT !.status = "booked"]]
               \/ /\ appointment' = [appointment EXCEPT ![p] = [appointment[p] EXCEPT !.status = "rejected"]]
          /\ pc' = [pc EXCEPT !["Clerk"] = "clerkLoop"]

clerk == clerkLoop \/ decide

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == clerk
           \/ (\E self \in Patients: patient(self))
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ \A self \in Patients : WF_vars(patient(self))
        /\ WF_vars(clerk)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
================================
