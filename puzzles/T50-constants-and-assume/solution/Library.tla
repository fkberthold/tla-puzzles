---- MODULE Library ----
EXTENDS Integers, TLC

CONSTANT Capacity

ASSUME Capacity \in Nat
ASSUME Capacity >= 1

(*--algorithm Library {
  variables books = Capacity, ops = 0;

  define {
    TypeOK == books \in 0..Capacity /\ ops \in 0..5
    Bounded == books >= 0 /\ books <= Capacity
  }

  fair process (clerk = "Clerk") {
    work:
      while (ops < 5) {
        either {
          await books > 0;
          books := books - 1;
        } or {
          await books < Capacity;
          books := books + 1;
        };
        ops := ops + 1;
      }
  }
}
*)
\* BEGIN TRANSLATION
\* END TRANSLATION
====
