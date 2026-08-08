------------------------------- MODULE Ledger -------------------------------
(***************************************************************************)
(* SEEDED VARIANT: `Deposit` is off by one.                                 *)
(*                                                                          *)
(* The reference guards with `balance[a] < MaxBalance`; here it is          *)
(* `balance[a] <= MaxBalance`, so a balance reaches MaxBalance + 1 and then *)
(* stops.  The mutated state space is still FINITE, which is deliberate:    *)
(* dropping the guard outright would make it unbounded, and a submission    *)
(* too weak to catch the bug would then time out instead of exiting 0.  The *)
(* MISSED row needs rc=0, not rc=124.                                       *)
(*                                                                          *)
(* The bug is only expressible over the constant.  A property that does not *)
(* mention MaxBalance cannot catch it, which is what makes this variant     *)
(* worth having in a fixture about the constants channel.                   *)
(***************************************************************************)
EXTENDS Naturals

CONSTANTS Accounts,
          MaxBalance

VARIABLE balance

vars == << balance >>

Init == balance = [a \in Accounts |-> 0]

Deposit(a)  == /\ balance[a] <= MaxBalance
               /\ balance' = [balance EXCEPT ![a] = @ + 1]

Withdraw(a) == /\ balance[a] > 0
               /\ balance' = [balance EXCEPT ![a] = @ - 1]

Next == \E a \in Accounts : Deposit(a) \/ Withdraw(a)

Spec == Init /\ [][Next]_vars

=============================================================================
