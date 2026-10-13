---- MODULE Collatz ----
EXTENDS Naturals, Sequences, TLC
CONSTANT N

(* --fair algorithm collatz {
     variables n = N;
     procedure hop() {
       h0: assert n > 1;
           if (n % 2 = 0) { n := n \div 2 } else { n := 3 * n + 1 };
           return }
     { main: while (n # 1) { call hop() } }
   } *)
\* BEGIN TRANSLATION (chksum(pcal) = "7c28162a" /\ chksum(tla) = "baced96")
VARIABLES pc, n, stack

vars == << pc, n, stack >>

Init == (* Global variables *)
        /\ n = N
        /\ stack = << >>
        /\ pc = "main"

h0 == /\ pc = "h0"
      /\ Assert(n > 1, "Failure of assertion at line 8, column 12.")
      /\ IF n % 2 = 0
            THEN /\ n' = (n \div 2)
            ELSE /\ n' = 3 * n + 1
      /\ pc' = Head(stack).pc
      /\ stack' = Tail(stack)

hop == h0

main == /\ pc = "main"
        /\ IF n # 1
              THEN /\ stack' = << [ procedure |->  "hop",
                                    pc        |->  "main" ] >>
                                \o stack
                   /\ pc' = "h0"
              ELSE /\ pc' = "Done"
                   /\ stack' = stack
        /\ n' = n

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == pc = "Done" /\ UNCHANGED vars

Next == hop \/ main
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(Next)

Termination == <>(pc = "Done")

\* END TRANSLATION 

Depth == Len(stack) <= 1

Peak == n <= 52
====
