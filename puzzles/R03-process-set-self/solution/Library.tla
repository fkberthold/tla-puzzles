---- MODULE Library ----
EXTENDS Integers, FiniteSets, TLC

(*--algorithm Library {
  variables available = 1, holders = {};

  define {
    TypeOK == available \in -1..1 /\ holders \subseteq {"Pat1", "Pat2"}
    NoOverborrow == available >= 0  \* This WILL be violated!
  }

  fair process (patron \in {"Pat1", "Pat2"}) {
    inspect:
      if (available > 0) {
        goto borrow;
      } else {
        goto done;
      };
    borrow:
      available := available - 1;
      holders := holders \cup {self};
      goto done;
    done:
      skip;
  }
}

*)
\* BEGIN TRANSLATION (chksum(pcal) = "b2c1d7a4" /\ chksum(tla) = "820c1104")
VARIABLES available, holders, pc

(* define statement *)
TypeOK == available \in -1..1 /\ holders \subseteq {"Pat1", "Pat2"}
NoOverborrow == available >= 0


vars == << available, holders, pc >>

ProcSet == ({"Pat1", "Pat2"})

Init == (* Global variables *)
        /\ available = 1
        /\ holders = {}
        /\ pc = [self \in ProcSet |-> "inspect"]

inspect(self) == /\ pc[self] = "inspect"
                 /\ IF available > 0
                       THEN /\ pc' = [pc EXCEPT ![self] = "borrow"]
                       ELSE /\ pc' = [pc EXCEPT ![self] = "done"]
                 /\ UNCHANGED << available, holders >>

borrow(self) == /\ pc[self] = "borrow"
                /\ available' = available - 1
                /\ holders' = (holders \cup {self})
                /\ pc' = [pc EXCEPT ![self] = "done"]

done(self) == /\ pc[self] = "done"
              /\ TRUE
              /\ pc' = [pc EXCEPT ![self] = "Done"]
              /\ UNCHANGED << available, holders >>

patron(self) == inspect(self) \/ borrow(self) \/ done(self)

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == (\E self \in {"Pat1", "Pat2"}: patron(self))
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ \A self \in {"Pat1", "Pat2"} : WF_vars(patron(self))

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
================================
