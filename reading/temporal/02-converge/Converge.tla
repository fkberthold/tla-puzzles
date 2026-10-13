---- MODULE Converge ----
EXTENDS Naturals

CONSTANT N
ASSUME N \in 2..9

Node == 0..N-1
Left(n) == (n + N - 1) % N
Top == N - 1

VARIABLE best
vars == <<best>>

TypeOK == best \in [Node -> Node]

Init == best = [n \in Node |-> n]

Learn(n) ==
  /\ best[Left(n)] > best[n]
  /\ best' = [best EXCEPT ![n] = best[Left(n)]]

Next == \E n \in Node : Learn(n)

Fairness == \A n \in Node : WF_vars(Learn(n))

Spec == Init /\ [][Next]_vars /\ Fairness

NeverLowers == [][\A n \in Node : best'[n] >= best[n]]_vars

Settles == <>[](\A n \in Node : best[n] = Top)
====
