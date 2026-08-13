---- MODULE LoadingBay ----
\* Exercise 3 reference solution.
\*
\* One loading bay, several hauliers, each of whom docks and leaves for ever.
\* A haulier can only take the bay while it is free, so it is only
\* intermittently able to move. Weak fairness is not enough to keep every
\* haulier moving, and `EveryoneKeepsDocking` fails under it. `fair+` is strong
\* fairness, and it is what this property needs.

EXTENDS TLC

CONSTANTS Hauliers, NULL

ASSUME NULL \notin Hauliers

\* Defined and deliberately NOT declared in the .cfg. The hauliers are
\* interchangeable, so a symmetry set is exactly the optimisation you would
\* reach for, and chapter 9 says you cannot have it alongside a liveness
\* property. reports/authoring.md records what TLC actually does when you try.
Perms == Permutations(Hauliers)

(*--algorithm loadingbay {
  variables bay = NULL;

  define {
    BayOK == bay = NULL \/ bay \in Hauliers

    EveryoneKeepsDocking == \A h \in Hauliers: []<>(bay = h)
  }

  fair+ process (H \in Hauliers) {
    Wait:
      while (TRUE) {
        await bay = NULL;
        bay := self;
        Go:
          bay := NULL;
      }
  }
}*)
\* BEGIN TRANSLATION (chksum(pcal) = "fe9c1d4a" /\ chksum(tla) = "7cfd5801")
VARIABLES pc, bay

(* define statement *)
BayOK == bay = NULL \/ bay \in Hauliers

EveryoneKeepsDocking == \A h \in Hauliers: []<>(bay = h)


vars == << pc, bay >>

ProcSet == (Hauliers)

Init == (* Global variables *)
        /\ bay = NULL
        /\ pc = [self \in ProcSet |-> "Wait"]

Wait(self) == /\ pc[self] = "Wait"
              /\ bay = NULL
              /\ bay' = self
              /\ pc' = [pc EXCEPT ![self] = "Go"]

Go(self) == /\ pc[self] = "Go"
            /\ bay' = NULL
            /\ pc' = [pc EXCEPT ![self] = "Wait"]

H(self) == Wait(self) \/ Go(self)

Next == (\E self \in Hauliers: H(self))

Spec == /\ Init /\ [][Next]_vars
        /\ \A self \in Hauliers : SF_vars(H(self))

\* END TRANSLATION 
====
