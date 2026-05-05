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
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
