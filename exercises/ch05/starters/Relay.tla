---- MODULE Relay ----
\* GIVEN module for exercise 4. Nothing to fill in. Read it, predict,
\* run it. The worked write-up is under references/ex4-relay/.
\* Runners is a set of model values. Nothing in this module can tell one
\* runner from another, which is exactly the condition a symmetry set needs.
\* Perms is the command line spelling of the toolbox "symmetry" checkbox.
\* The .cfg names it with a SYMMETRY line.
EXTENDS Integers, TLC

CONSTANT Runners

Perms == Permutations(Runners)

(*--algorithm relay {
variables carrier \in Runners, touched = {}, passes = 0;

define {
  TouchedAreRunners == touched \subseteq Runners
  CarrierIsRunner == carrier \in Runners
}

{
  Pass:
    while (passes < 2) {
      touched := touched \union {carrier};
      with (r \in Runners) {
        carrier := r;
      };
      passes := passes + 1;
    };
}
}
*)
\* BEGIN TRANSLATION (chksum(pcal) = "af4e467c" /\ chksum(tla) = "cc9a8f2f")
VARIABLES pc, carrier, touched, passes

(* define statement *)
TouchedAreRunners == touched \subseteq Runners
CarrierIsRunner == carrier \in Runners


vars == << pc, carrier, touched, passes >>

Init == (* Global variables *)
        /\ carrier \in Runners
        /\ touched = {}
        /\ passes = 0
        /\ pc = "Pass"

Pass == /\ pc = "Pass"
        /\ IF passes < 2
              THEN /\ touched' = (touched \union {carrier})
                   /\ \E r \in Runners:
                        carrier' = r
                   /\ passes' = passes + 1
                   /\ pc' = "Pass"
              ELSE /\ pc' = "Done"
                   /\ UNCHANGED << carrier, touched, passes >>

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == pc = "Done" /\ UNCHANGED vars

Next == Pass
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(pc = "Done")

\* END TRANSLATION 
====
