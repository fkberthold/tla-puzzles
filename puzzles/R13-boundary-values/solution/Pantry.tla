---- MODULE Pantry ----
EXTENDS Integers, TLC

CONSTANT MaxJars

(*--algorithm Pantry {
  variables jars = 0;

  define {
    TypeOK == jars \in 0..MaxJars
    NeverNegative == jars >= 0
  }

  fair process (cook = "Cook") {
    work:
      while (jars < MaxJars) {
        either {
          jars := jars + 1;
        } or {
          if (jars > 0) { jars := jars - 1; };
        };
      }
  }
}
*)
\* BEGIN TRANSLATION (chksum(pcal) = "257eefa4" /\ chksum(tla) = "c53f2b61")
VARIABLES jars, pc

(* define statement *)
TypeOK == jars \in 0..MaxJars
NeverNegative == jars >= 0


vars == << jars, pc >>

ProcSet == {"Cook"}

Init == (* Global variables *)
        /\ jars = 0
        /\ pc = [self \in ProcSet |-> "work"]

work == /\ pc["Cook"] = "work"
        /\ IF jars < MaxJars
              THEN /\ \/ /\ jars' = jars + 1
                      \/ /\ IF jars > 0
                               THEN /\ jars' = jars - 1
                               ELSE /\ TRUE
                                    /\ jars' = jars
                   /\ pc' = [pc EXCEPT !["Cook"] = "work"]
              ELSE /\ pc' = [pc EXCEPT !["Cook"] = "Done"]
                   /\ jars' = jars

cook == work

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == cook
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(cook)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION
================================
