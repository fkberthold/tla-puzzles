---- MODULE Account ----
EXTENDS Integers, TLC

(*--algorithm Account {
  variables
    account = [balance |-> 0, owner |-> "Bob", frozen |-> FALSE],
    step = 0;

  define {
    Owner == account.owner
    Balance == account.balance
    IsFrozen == account.frozen

    TypeOK ==
      /\ account.balance \in 0..200
      /\ account.owner \in {"Bob"}
      /\ account.frozen \in BOOLEAN
      /\ step \in 0..4
    OwnerStable == Owner = "Bob"
    EndsCorrect == step = 4 => (Balance = 70 /\ IsFrozen)
  }

  fair process (bank = "Bank") {
    deposit:
      account := [account EXCEPT !.balance = @ + 100];
      step := step + 1;
    withdraw:
      account := [account EXCEPT !.balance = @ - 30];
      step := step + 1;
    freeze:
      account := [account EXCEPT !.frozen = TRUE];
      step := step + 1;
    finish:
      step := step + 1;
  }
}

*)
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
