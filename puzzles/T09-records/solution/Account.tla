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
\* BEGIN TRANSLATION (chksum(pcal) = "ad47026f" /\ chksum(tla) = "56ccec82")
VARIABLES account, step, pc

(* define statement *)
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


vars == << account, step, pc >>

ProcSet == {"Bank"}

Init == (* Global variables *)
        /\ account = [balance |-> 0, owner |-> "Bob", frozen |-> FALSE]
        /\ step = 0
        /\ pc = [self \in ProcSet |-> "deposit"]

deposit == /\ pc["Bank"] = "deposit"
           /\ account' = [account EXCEPT !.balance = @ + 100]
           /\ step' = step + 1
           /\ pc' = [pc EXCEPT !["Bank"] = "withdraw"]

withdraw == /\ pc["Bank"] = "withdraw"
            /\ account' = [account EXCEPT !.balance = @ - 30]
            /\ step' = step + 1
            /\ pc' = [pc EXCEPT !["Bank"] = "freeze"]

freeze == /\ pc["Bank"] = "freeze"
          /\ account' = [account EXCEPT !.frozen = TRUE]
          /\ step' = step + 1
          /\ pc' = [pc EXCEPT !["Bank"] = "finish"]

finish == /\ pc["Bank"] = "finish"
          /\ step' = step + 1
          /\ pc' = [pc EXCEPT !["Bank"] = "Done"]
          /\ UNCHANGED account

bank == deposit \/ withdraw \/ freeze \/ finish

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == bank
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(bank)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
================================
