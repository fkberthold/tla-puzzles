---- MODULE Cloakroom ----
\* Exercise 3 reference answer.
\*
\* Three guests, two hooks. The third guest arrives to find `free` empty, and
\* `CHOOSE h \in free : TRUE` has no answer to give. The `if` is the spec
\* saying out loud what happens then: that guest keeps its coat.
EXTENDS Integers

Hooks == 1..2
Guests == 1..3

(*--algorithm cloakroom {
  variables free = Hooks, coat = [h \in Hooks |-> 0];

  define {
    CoatsAreGuests == \A h \in Hooks : coat[h] \in {0} \cup Guests

    UsedHooksAreTaken == \A h \in Hooks : (coat[h] # 0) => (h \notin free)
  }

  process (guest \in Guests)
  {
    Hang:
      if (free # {}) {
        with (h = CHOOSE x \in free : TRUE) {
          coat[h] := self;
          free := free \ {h};
        };
      };
  }
}
*)
\* BEGIN TRANSLATION (chksum(pcal) = "b157db12" /\ chksum(tla) = "deb635e5")
VARIABLES pc, free, coat

(* define statement *)
CoatsAreGuests == \A h \in Hooks : coat[h] \in {0} \cup Guests

UsedHooksAreTaken == \A h \in Hooks : (coat[h] # 0) => (h \notin free)


vars == << pc, free, coat >>

ProcSet == (Guests)

Init == (* Global variables *)
        /\ free = Hooks
        /\ coat = [h \in Hooks |-> 0]
        /\ pc = [self \in ProcSet |-> "Hang"]

Hang(self) == /\ pc[self] = "Hang"
              /\ IF free # {}
                    THEN /\ LET h == CHOOSE x \in free : TRUE IN
                              /\ coat' = [coat EXCEPT ![h] = self]
                              /\ free' = free \ {h}
                    ELSE /\ TRUE
                         /\ UNCHANGED << free, coat >>
              /\ pc' = [pc EXCEPT ![self] = "Done"]

guest(self) == Hang(self)

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == (\E self \in Guests: guest(self))
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
====
