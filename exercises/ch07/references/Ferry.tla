---- MODULE Ferry ----
\* Exercise 5 reference answer.
\*
\* A ferry moves crates from the near bank to the far bank. A crossing either
\* lands or it does not, and the spec says nothing at all about why one fails.
\* That silence is the point. `either ... or skip` buys the whole sad path for
\* two words, and the crate is still aboard for the next attempt.
\*
\* `NothingLost` is the invariant that survives the abstraction. Wherever a
\* crate is, it is somewhere.
EXTENDS Integers

CONSTANT Crates

MaxTrips == 3

(*--algorithm ferry {
  variables
    near = Crates,
    aboard = 0,
    far = 0,
    trips = 0;

  define {
    TypeOK == /\ near \in 0..Crates
              /\ aboard \in 0..Crates
              /\ far \in 0..Crates

    NothingLost == near + aboard + far = Crates
  }

  {
    Sail:
      while (trips < MaxTrips) {
        Load:
          if (near > 0) {
            near := near - 1 || aboard := aboard + 1;
          };
        Cross:
          either {
            \* The crossing lands. Everything aboard comes off.
            far := far + aboard || aboard := 0;
          } or {
            \* The crossing does not land. We do not model why.
            skip;
          };
          trips := trips + 1;
      };
  }
}
*)
\* BEGIN TRANSLATION (chksum(pcal) = "6cdef690" /\ chksum(tla) = "a09f0056")
VARIABLES pc, near, aboard, far, trips

(* define statement *)
TypeOK == /\ near \in 0..Crates
          /\ aboard \in 0..Crates
          /\ far \in 0..Crates

NothingLost == near + aboard + far = Crates


vars == << pc, near, aboard, far, trips >>

Init == (* Global variables *)
        /\ near = Crates
        /\ aboard = 0
        /\ far = 0
        /\ trips = 0
        /\ pc = "Sail"

Sail == /\ pc = "Sail"
        /\ IF trips < MaxTrips
              THEN /\ pc' = "Load"
              ELSE /\ pc' = "Done"
        /\ UNCHANGED << near, aboard, far, trips >>

Load == /\ pc = "Load"
        /\ IF near > 0
              THEN /\ /\ aboard' = aboard + 1
                      /\ near' = near - 1
              ELSE /\ TRUE
                   /\ UNCHANGED << near, aboard >>
        /\ pc' = "Cross"
        /\ UNCHANGED << far, trips >>

Cross == /\ pc = "Cross"
         /\ \/ /\ /\ aboard' = 0
                  /\ far' = far + aboard
            \/ /\ TRUE
               /\ UNCHANGED <<aboard, far>>
         /\ trips' = trips + 1
         /\ pc' = "Sail"
         /\ near' = near

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == pc = "Done" /\ UNCHANGED vars

Next == Sail \/ Load \/ Cross
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(pc = "Done")

\* END TRANSLATION 
====
