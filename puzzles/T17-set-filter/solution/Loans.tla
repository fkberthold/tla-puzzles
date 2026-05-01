---- MODULE Loans ----
EXTENDS Integers, TLC

(*--algorithm Loans {
  variables
    loaned = [b \in 1..4 |-> IF b = 1 THEN "alice" ELSE "none"],
    outOnLoan = {},
    available = {},
    phase = 0;

  define {
    Books == DOMAIN loaned

    TypeOK ==
      /\ Books = 1..4
      /\ outOnLoan \subseteq Books
      /\ available \subseteq Books
      /\ phase \in 0..3
    Disjoint == outOnLoan \cap available = {}
    EndsCorrect == phase = 3 => (outOnLoan = {1} /\ available = {2, 3, 4})
  }

  fair process (librarian = "Lib") {
    scanLoaned:
      outOnLoan := {b \in 1..4 : loaned[b] /= "none"};
      phase := phase + 1;
    scanAvailable:
      available := {b \in 1..4 : loaned[b] = "none"};
      phase := phase + 1;
    finish:
      phase := phase + 1;
  }
}

*)
\* BEGIN TRANSLATION (chksum(pcal) = "5dc77f27" /\ chksum(tla) = "890e50bd")
VARIABLES loaned, outOnLoan, available, phase, pc

(* define statement *)
Books == DOMAIN loaned

TypeOK ==
  /\ Books = 1..4
  /\ outOnLoan \subseteq Books
  /\ available \subseteq Books
  /\ phase \in 0..3
Disjoint == outOnLoan \cap available = {}
EndsCorrect == phase = 3 => (outOnLoan = {1} /\ available = {2, 3, 4})


vars == << loaned, outOnLoan, available, phase, pc >>

ProcSet == {"Lib"}

Init == (* Global variables *)
        /\ loaned = [b \in 1..4 |-> IF b = 1 THEN "alice" ELSE "none"]
        /\ outOnLoan = {}
        /\ available = {}
        /\ phase = 0
        /\ pc = [self \in ProcSet |-> "scanLoaned"]

scanLoaned == /\ pc["Lib"] = "scanLoaned"
              /\ outOnLoan' = {b \in 1..4 : loaned[b] /= "none"}
              /\ phase' = phase + 1
              /\ pc' = [pc EXCEPT !["Lib"] = "scanAvailable"]
              /\ UNCHANGED << loaned, available >>

scanAvailable == /\ pc["Lib"] = "scanAvailable"
                 /\ available' = {b \in 1..4 : loaned[b] = "none"}
                 /\ phase' = phase + 1
                 /\ pc' = [pc EXCEPT !["Lib"] = "finish"]
                 /\ UNCHANGED << loaned, outOnLoan >>

finish == /\ pc["Lib"] = "finish"
          /\ phase' = phase + 1
          /\ pc' = [pc EXCEPT !["Lib"] = "Done"]
          /\ UNCHANGED << loaned, outOnLoan, available >>

librarian == scanLoaned \/ scanAvailable \/ finish

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == librarian
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(librarian)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
================================
