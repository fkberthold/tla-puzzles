---- MODULE Account ----
EXTENDS Integers, Apalache

CONSTANT
  \* @type: Int;
  Limit

\* @type: Int;
VARIABLE balance

vars == << balance >>

Init == balance := 0

Deposit ==
  /\ balance < 100
  /\ \E amt \in 1..50:
       balance' := balance + amt

Withdraw ==
  /\ \E amt \in 1..50:
       /\ balance - amt >= Limit
       /\ balance' := balance - amt

Done ==
  /\ balance = 100
  /\ UNCHANGED balance

Next == Deposit \/ Withdraw \/ Done

Spec == Init /\ [][Next]_vars

BalanceFloor == balance >= Limit

\* TLC config workaround: TLC's .cfg parser does not accept negative-integer
\* literals, so we expose a helper operator and use `<-` (override) in the cfg.
LimitVal == -50

\* ConstInit: Apalache will verify BalanceFloor for all Limit in this range,
\* via `apalache-mc check --cinit=ConstInit Account.tla`.
\* TLC ignores this; for TLC, see Account.cfg for a concrete Limit value.
ConstInit ==
  Limit \in -50..-10
====
