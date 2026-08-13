---- MODULE Kiln ----
\* Exercise 2 starter. Two holes, marked TODO.
\*
\* A kiln loads, heats, holds the soak for a bounded number of turns, then
\* cools and vents. The firing is meant to always reach "cooled".
\*
\* This file is delivered already translated, so TODO 2 sits in it TWICE: once
\* in the PlusCal comment below, and once again in the translated section at
\* the foot of the file. TLC reads only the translated copy. Fill the copy in
\* the PlusCal comment and run `pcal Kiln.tla`, which rewrites the translation
\* from it. Editing the translated copy by hand appears to work, and the next
\* `pcal` run undoes it.
EXTENDS Integers

MaxSoak == 2

Stages == {"loading", "heating", "soaking", "cooling", "cooled"}

(*--algorithm kiln {
  variables stage = "loading", soaks = 0;

  define {
    StageOK == stage \in Stages

    \* TODO 2. The firing always reaches the last stage. One temporal
    \* operator over one state predicate. `stage = "cooled"` is the
    \* predicate. Pick the operator that says "at some state, now or later".
    FiringFinishes == TODO_2
  }

  \* TODO 1. This process can stop dead at any label, and the property you
  \* write above cannot hold while that is allowed. Add the one modifier that
  \* rules it out, immediately before the word `process`.
  process (Fire = "fire") {
    Load:
      stage := "heating";
    Heat:
      stage := "soaking";
    Soak:
      while (soaks < MaxSoak) {
        soaks := soaks + 1;
      };
    Cool:
      stage := "cooling";
    Vent:
      stage := "cooled";
  }
}*)
\* BEGIN TRANSLATION (chksum(pcal) = "676786e1" /\ chksum(tla) = "958f1f23")
VARIABLES pc, stage, soaks

(* define statement *)
StageOK == stage \in Stages




FiringFinishes == TODO_2


vars == << pc, stage, soaks >>

ProcSet == {"fire"}

Init == (* Global variables *)
        /\ stage = "loading"
        /\ soaks = 0
        /\ pc = [self \in ProcSet |-> "Load"]

Load == /\ pc["fire"] = "Load"
        /\ stage' = "heating"
        /\ pc' = [pc EXCEPT !["fire"] = "Heat"]
        /\ soaks' = soaks

Heat == /\ pc["fire"] = "Heat"
        /\ stage' = "soaking"
        /\ pc' = [pc EXCEPT !["fire"] = "Soak"]
        /\ soaks' = soaks

Soak == /\ pc["fire"] = "Soak"
        /\ IF soaks < MaxSoak
              THEN /\ soaks' = soaks + 1
                   /\ pc' = [pc EXCEPT !["fire"] = "Soak"]
              ELSE /\ pc' = [pc EXCEPT !["fire"] = "Cool"]
                   /\ soaks' = soaks
        /\ stage' = stage

Cool == /\ pc["fire"] = "Cool"
        /\ stage' = "cooling"
        /\ pc' = [pc EXCEPT !["fire"] = "Vent"]
        /\ soaks' = soaks

Vent == /\ pc["fire"] = "Vent"
        /\ stage' = "cooled"
        /\ pc' = [pc EXCEPT !["fire"] = "Done"]
        /\ soaks' = soaks

Fire == Load \/ Heat \/ Soak \/ Cool \/ Vent

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == Fire
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
====
