---- MODULE LoadingBay ----
\* Exercise 3 starter. One hole, marked TODO, plus one word to change later.
\*
\* One loading bay, several hauliers. A haulier waits for the bay to be free,
\* takes it, then releases it, for ever. The bay is the contested resource.
\*
\* This file is delivered already translated, so TODO 1 sits in it TWICE: once
\* in the PlusCal comment below, and once again in the translated section at
\* the foot of the file. TLC reads only the translated copy. Fill the copy in
\* the PlusCal comment and run `pcal starters/LoadingBay.tla`, which rewrites the
\* translation from it. Editing the translated copy by hand appears to work,
\* and the next `pcal` run undoes it.
EXTENDS TLC

CONSTANTS Hauliers, NULL

ASSUME NULL \notin Hauliers

\* Defined, and deliberately not named in the .cfg. See the exercise text.
Perms == Permutations(Hauliers)

(*--algorithm loadingbay {
  variables bay = NULL;

  define {
    BayOK == bay = NULL \/ bay \in Hauliers

    \* TODO 1. Every haulier keeps getting the bay, for ever. Not "gets it
    \* once", and not "ends up holding it". Quantify over `Hauliers` and put
    \* the right two-operator temporal shape around `bay = h`.
    EveryoneKeepsDocking == TODO_1
  }

  \* The modifier below is WEAK fairness. Exercise step 3 asks you to change
  \* this one word. Leave it alone until then.
  fair process (H \in Hauliers) {
    Wait:
      while (TRUE) {
        await bay = NULL;
        bay := self;
        Go:
          bay := NULL;
      }
  }
}*)
\* BEGIN TRANSLATION (chksum(pcal) = "a29335e6" /\ chksum(tla) = "ceaeb8ee")
VARIABLES pc, bay

(* define statement *)
BayOK == bay = NULL \/ bay \in Hauliers




EveryoneKeepsDocking == TODO_1


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
        /\ \A self \in Hauliers : WF_vars(H(self))

\* END TRANSLATION 
====
