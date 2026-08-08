------------------------------- MODULE Ledger -------------------------------
(***************************************************************************)
(* THE REFERENCE SPEC for the PARAMETERISED matrix (bead tla-40y).          *)
(*                                                                          *)
(* crossing/ is closed: it declares no CONSTANT, so it exercises the whole  *)
(* matrix without ever asking whether a constant could be assigned.  Most   *)
(* real specs are not closed.  The Stage 3 pilot's reference declares       *)
(* `Departments` and `MaxAmendments`, and the matrix could not drive it at  *)
(* all until the reference package gained a `constants.cfg`.  This module   *)
(* is the smallest thing that would have caught that.                       *)
(*                                                                          *)
(* One balance per account, moving up and down between 0 and MaxBalance.    *)
(* With the assignment in ../constants.cfg -- two accounts, MaxBalance 2 -- *)
(* that is nine reachable states, which keeps every TLC run in the matrix   *)
(* cheap; the matrix runs 2 x (1 + N) of them.                              *)
(*                                                                          *)
(* Like Crossing, this module defines NO invariant.  The invariant is what  *)
(* the learner supplies, and redefining an EXTENDS-inherited name is a SANY *)
(* error rather than a shadowing, so a module that shipped its own `Inv`    *)
(* would collide with every submission.                                     *)
(***************************************************************************)
EXTENDS Naturals

CONSTANTS Accounts,     \* the set of accounts
          MaxBalance    \* the largest balance the reference ever reaches

VARIABLE balance

vars == << balance >>

Init == balance = [a \in Accounts |-> 0]

Deposit(a)  == /\ balance[a] < MaxBalance
               /\ balance' = [balance EXCEPT ![a] = @ + 1]

Withdraw(a) == /\ balance[a] > 0
               /\ balance' = [balance EXCEPT ![a] = @ - 1]

Next == \E a \in Accounts : Deposit(a) \/ Withdraw(a)

Spec == Init /\ [][Next]_vars

=============================================================================
