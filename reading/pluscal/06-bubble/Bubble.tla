---- MODULE Bubble ----
EXTENDS Naturals, FiniteSets

(* --fair algorithm bubble {
     variables a \in [1..4 -> 1..4];
     define {
       Bad == {i \in 1..3 : a[i] > a[i + 1]}
       Pairs == {p \in (1..4) \X (1..4) : p[1] < p[2]}
       Inver == {p \in Pairs : a[p[1]] > a[p[2]]}
     }
     { pass: while (Bad # {}) {
               with (i \in Bad) {
                 a[i] := a[i + 1] || a[i + 1] := a[i] } } }
   } *)
\* BEGIN TRANSLATION (chksum(pcal) = "7c28162a" /\ chksum(tla) = "56872cf")
VARIABLES pc, a

(* define statement *)
Bad == {i \in 1..3 : a[i] > a[i + 1]}
Pairs == {p \in (1..4) \X (1..4) : p[1] < p[2]}
Inver == {p \in Pairs : a[p[1]] > a[p[2]]}


vars == << pc, a >>

Init == (* Global variables *)
        /\ a \in [1..4 -> 1..4]
        /\ pc = "pass"

pass == /\ pc = "pass"
        /\ IF Bad # {}
              THEN /\ \E i \in Bad:
                        a' = [a EXCEPT ![i] = a[i + 1],
                                       ![i + 1] = a[i]]
                   /\ pc' = "pass"
              ELSE /\ pc' = "Done"
                   /\ a' = a

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == pc = "Done" /\ UNCHANGED vars

Next == pass
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(Next)

Termination == <>(pc = "Done")

\* END TRANSLATION 

TypeOK == a \in [1..4 -> 1..4]

Settled == (pc = "Done") => Bad = {}

Shrinks == [][a' # a => Cardinality(Inver') = Cardinality(Inver) - 1]_vars
====
