---- MODULE Kiln ----
\* Exercise 2 reference solution.
\*
\* A kiln loads, heats, holds the soak for a bounded number of turns, then
\* cools. `FiringFinishes` says the firing always reaches the end. It only
\* holds because the process is fair. Drop the `fair` and the same spec fails,
\* because a behaviour is allowed to stutter for ever at any point.
EXTENDS Integers

MaxSoak == 2

Stages == {"loading", "heating", "soaking", "cooling", "cooled"}

(*--algorithm kiln {
  variables stage = "loading", soaks = 0;

  define {
    StageOK == stage \in Stages

    FiringFinishes == <>(stage = "cooled")
  }

  fair process (Fire = "fire") {
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
\* BEGIN TRANSLATION (chksum(pcal) = "11fd8ac1" /\ chksum(tla) = "4c8aefd0")
VARIABLES pc, stage, soaks

(* define statement *)
StageOK == stage \in Stages

FiringFinishes == <>(stage = "cooled")


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

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(Fire)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
====
