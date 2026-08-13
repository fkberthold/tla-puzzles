---- MODULE Depot ----
\* Exercise 1 starter. Three holes, marked TODO.
\*
\* Crates wait on the quay. A loader takes them one at a time and writes each
\* one into the loading order. Nothing decides which crate goes next, so the
\* pick is nondeterministic and TLC walks every loading order there is.
\*
\* The loop counts picks rather than watching the quay. That is deliberate,
\* so leave it alone.
\*
\* `NoRepeats` is written for you. It is the model for the one you write.
EXTENDS Integers, Sequences, FiniteSets

CONSTANT Crates
ASSUME Crates # {}

(*--algorithm depot {
  variables
    waiting = Crates,
    order = << >>;

  define {
    Loaded == { order[i] : i \in 1..Len(order) }

    \* TODO 1. No crate is lost. Every crate is either still waiting on the
    \* quay or already in the loading order, and between them they account
    \* for all of `Crates`.
    Conserved == TODO_1

    NoRepeats == Cardinality(Loaded) = Len(order)
  }

  {
    Load:
      while (Len(order) < Cardinality(Crates)) {
        \* TODO 2. Take any one of the crates that is still waiting. What you
        \* draw from here is a variable, not a constant, and it shrinks as the
        \* loop runs.
        with (crate \in TODO_2) {
          \* TODO 3. The crate you just took is no longer waiting.
          waiting := TODO_3 || order := Append(order, crate);
        };
      };
  }
}
*)
\* BEGIN TRANSLATION (chksum(pcal) = "45ec9c73" /\ chksum(tla) = "a2b15094")
VARIABLES pc, waiting, order

(* define statement *)
Loaded == { order[i] : i \in 1..Len(order) }




Conserved == TODO_1

NoRepeats == Cardinality(Loaded) = Len(order)


vars == << pc, waiting, order >>

Init == (* Global variables *)
        /\ waiting = Crates
        /\ order = << >>
        /\ pc = "Load"

Load == /\ pc = "Load"
        /\ IF Len(order) < Cardinality(Crates)
              THEN /\ \E crate \in TODO_2:
                        /\ order' = Append(order, crate)
                        /\ waiting' = TODO_3
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
