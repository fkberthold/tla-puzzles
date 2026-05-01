---- MODULE Counter ----
EXTENDS Integers, TLC

(*--algorithm Counter {
  variables n = 0;

  define {
    TypeOK == n \in 0..3
    Settles == <>[](n = 3)
  }

  fair process (counter = "Counter") {
    tick:
      while (TRUE) {
        either {
          if (n < 3) {
            n := n + 1;
          };
        } or {
          skip;
        };
      }
  }
}

*)
\* BEGIN TRANSLATION (chksum(pcal) = "70f95992" /\ chksum(tla) = "ee83be52")
VARIABLE n

(* define statement *)
TypeOK == n \in 0..3
Settles == <>[](n = 3)


vars == << n >>

ProcSet == {"Counter"}

Init == (* Global variables *)
        /\ n = 0

counter == \/ /\ IF n < 3
                    THEN /\ n' = n + 1
                    ELSE /\ TRUE
                         /\ n' = n
           \/ /\ TRUE
              /\ n' = n

Next == counter

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(counter)

\* END TRANSLATION 
================================
