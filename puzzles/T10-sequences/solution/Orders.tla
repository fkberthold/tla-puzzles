---- MODULE Orders ----
EXTENDS Integers, Sequences, TLC

(*--algorithm Orders {
  variables orders = <<>>, served = <<>>, phase = 0;

  define {
    QueueLen == Len(orders)
    NextUp == IF orders = <<>> THEN "none" ELSE orders[1]
    MostRecent == IF orders = <<>> THEN "none" ELSE orders[Len(orders)]

    TypeOK ==
      /\ QueueLen \in 0..3
      /\ Len(served) \in 0..1
      /\ phase \in 0..3
    ServedOnlyAfterAllTaken == Len(served) = 1 => phase = 3
    NoExtraServing == Len(served) <= 1
  }

  fair process (barista = "Barista") {
    take:
      while (phase < 3) {
        with (o \in {"latte", "mocha", "americano"}) {
          orders := Append(orders, o);
        };
        phase := phase + 1;
      };
    serve:
      if (Len(orders) > 0) {
        served := Append(served, Head(orders));
        orders := Tail(orders);
      };
  }
}

*)
\* BEGIN TRANSLATION (chksum(pcal) = "4792552b" /\ chksum(tla) = "7ee3c0b9")
VARIABLES orders, served, phase, pc

(* define statement *)
QueueLen == Len(orders)
NextUp == IF orders = <<>> THEN "none" ELSE orders[1]
MostRecent == IF orders = <<>> THEN "none" ELSE orders[Len(orders)]

TypeOK ==
  /\ QueueLen \in 0..3
  /\ Len(served) \in 0..1
  /\ phase \in 0..3
ServedOnlyAfterAllTaken == Len(served) = 1 => phase = 3
NoExtraServing == Len(served) <= 1


vars == << orders, served, phase, pc >>

ProcSet == {"Barista"}

Init == (* Global variables *)
        /\ orders = <<>>
        /\ served = <<>>
        /\ phase = 0
        /\ pc = [self \in ProcSet |-> "take"]

take == /\ pc["Barista"] = "take"
        /\ IF phase < 3
              THEN /\ \E o \in {"latte", "mocha", "americano"}:
                        orders' = Append(orders, o)
                   /\ phase' = phase + 1
                   /\ pc' = [pc EXCEPT !["Barista"] = "take"]
              ELSE /\ pc' = [pc EXCEPT !["Barista"] = "serve"]
                   /\ UNCHANGED << orders, phase >>
        /\ UNCHANGED served

serve == /\ pc["Barista"] = "serve"
         /\ IF Len(orders) > 0
               THEN /\ served' = Append(served, Head(orders))
                    /\ orders' = Tail(orders)
               ELSE /\ TRUE
                    /\ UNCHANGED << orders, served >>
         /\ pc' = [pc EXCEPT !["Barista"] = "Done"]
         /\ phase' = phase

barista == take \/ serve

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == barista
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(barista)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
================================
