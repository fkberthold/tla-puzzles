---- MODULE Stamps ----
EXTENDS Integers

CONSTANTS Small, Large, Max

\* Hygiene, and it is load bearing twice over. Two distinct stamp values,
\* and a bound high enough that 8..Max is not empty. An ASSUME over an
\* empty range is true and says nothing, so the second ASSUME below is
\* only worth reading because this line rules that out.
ASSUME Small \in 2..9 /\ Large \in 2..9 /\ Small < Large /\ Max \in 8..40

\* The whole claim: 0, 3, 5 and 6 are payable, so is everything from 8,
\* and the four amounts left over are not. Work out which four.
Payable == {0, 3, 5, 6} \cup (8..Max)
Gap == (0..Max) \ Payable

\* n is representable: some count of each stamp adds up to exactly n.
\* This is arithmetic about Small and Large. On its own it says nothing
\* about the machine below.
Representable(n) == \E i, j \in 0..Max : n = Small * i + Large * j

\* Half the theorem, and the half no invariant can carry. No single state
\* can say that every amount from 8 is reached, because a state knows
\* only its own amount. So this direction is asserted, and TLC evaluates
\* it before it generates a state rather than checking it against one.
ASSUME \A n \in 8..Max : Representable(n)

VARIABLE paid
vars == <<paid>>

\* Nat rather than 0..Max, and the CONSTRAINT below is why. TLC checks an
\* invariant on a state and prunes it afterwards, so a type written to the
\* bound is refuted by the first state over it.
TypeOK == paid \in Nat

Init == paid = 0

\* One stamp goes on, and nothing says which.
Stick ==
  \/ paid' = paid + Small
  \/ paid' = paid + Large

Next == Stick

Spec == Init /\ [][Next]_vars

\* The other half, and this is the one TLC really checks: no amount it
\* reaches is one of the four gaps.
NoGap == paid \notin Gap

Bounded == paid <= Max
====
