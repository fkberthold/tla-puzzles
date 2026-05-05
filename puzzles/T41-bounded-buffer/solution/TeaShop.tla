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
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
