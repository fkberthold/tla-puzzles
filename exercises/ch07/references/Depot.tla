---- MODULE Depot ----
\* Exercise 1 reference answer.
\*
\* Crates wait on the quay. A loader takes them one at a time and writes each
\* one into the loading order. Nothing decides which crate goes next, so the
\* pick is nondeterministic and TLC walks every loading order there is.
\*
\* The loop counts picks rather than watching the quay, so a wrong answer to
\* the draw set still terminates and still gets a verdict.
\*
\* The two invariants are the ones that survive the nondeterminism. Whatever
\* order the crates go in, none is lost and none is loaded twice.
EXTENDS Integers, Sequences, FiniteSets

CONSTANT Crates
ASSUME Crates # {}

(*--algorithm depot {
  variables
    waiting = Crates,
    order = << >>;

  define {
    Loaded == { order[i] : i \in 1..Len(order) }

    Conserved == Loaded \union waiting = Crates

    NoRepeats == Cardinality(Loaded) = Len(order)
  }

  {
    Load:
      while (Len(order) < Cardinality(Crates)) {
        with (crate \in waiting) {
          waiting := waiting \ {crate} || order := Append(order, crate);
        };
      };
  }
}
*)
\* BEGIN TRANSLATION (chksum(pcal) = "17ab60af" /\ chksum(tla) = "24474961")
VARIABLES pc, waiting, order

(* define statement *)
Loaded == { order[i] : i \in 1..Len(order) }

Conserved == Loaded \union waiting = Crates

NoRepeats == Cardinality(Loaded) = Len(order)


vars == << pc, waiting, order >>

Init == (* Global variables *)
        /\ waiting = Crates
        /\ order = << >>
        /\ pc = "Load"

Load == /\ pc = "Load"
        /\ IF Len(order) < Cardinality(Crates)
              THEN /\ \E crate \in waiting:
                        /\ order' = Append(order, crate)
                        /\ waiting' = waiting \ {crate}
                   /\ pc' = "Load"
              ELSE /\ pc' = "Done"
                   /\ UNCHANGED << waiting, order >>

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == pc = "Done" /\ UNCHANGED vars

Next == Load
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(pc = "Done")

\* END TRANSLATION 
====
