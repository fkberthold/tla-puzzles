---- MODULE Euclid ----
EXTENDS Naturals

CONSTANTS M, N
ASSUME M \in 1..12 /\ N \in 1..12

Divisors(k) == {d \in 1..12 : k % d = 0}

(* --algorithm euclid {
     variables x = M, y = N;
     { reduce: while (x # y) {
                 if (x > y) { x := x - y }
                 else { y := y - x } } }
   } *)
\* BEGIN TRANSLATION (chksum(pcal) = "b18ee4" /\ chksum(tla) = "5c58e758")
VARIABLES pc, x, y

vars == << pc, x, y >>

Init == (* Global variables *)
        /\ x = M
        /\ y = N
        /\ pc = "reduce"

reduce == /\ pc = "reduce"
          /\ IF x # y
                THEN /\ IF x > y
                           THEN /\ x' = x - y
                                /\ y' = y
                           ELSE /\ y' = y - x
                                /\ x' = x
                     /\ pc' = "reduce"
                ELSE /\ pc' = "Done"
                     /\ UNCHANGED << x, y >>

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == pc = "Done" /\ UNCHANGED vars

Next == reduce
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(Next)

Termination == <>(pc = "Done")

\* END TRANSLATION 

Common == Divisors(x) \cap Divisors(y)

Preserved == Common = Divisors(M) \cap Divisors(N)

Greatest ==
  (pc = "Done") => /\ x \in Common
                   /\ \A d \in Common : d <= x
====
