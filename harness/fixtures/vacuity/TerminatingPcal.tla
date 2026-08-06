----------------------- MODULE TerminatingPcal -----------------------
(***************************************************************************)
(* THE FALSE-POSITIVE CONTROL for dead-action detection.                    *)
(*                                                                          *)
(* A perfectly healthy PlusCal submission. It must come back NON_VACUOUS.   *)
(*                                                                          *)
(* PlusCal emits a `Terminating` action -- `pc = "Done" /\ UNCHANGED vars`  *)
(* -- into the Next of EVERY terminating algorithm. Under -coverage 1 that  *)
(* action reports 0 DISTINCT states and 1 TOTAL: it fires, and it discovers *)
(* nothing new, because a stutter step by construction re-finds the state   *)
(* it started in.                                                           *)
(*                                                                          *)
(* So a dead-action probe keyed on `distinct == 0` flags this fixture, and  *)
(* with it essentially every PlusCal submission in the problem set. The     *)
(* predicate is `total == 0`. This module is the fixture that holds that    *)
(* line; the algorithm is the one from puzzles/T01-the-light-switch, on     *)
(* which the behaviour was first measured.                                  *)
(***************************************************************************)
EXTENDS Integers

(*--algorithm LightSwitch {
  variables light = "off", count = 0;

  define {
    TypeOK == light \in {"on", "off"} /\ count \in 0..3
  }

  fair process (switcher = "Person") {
    toggle:
      while (count < 3) {
        if (light = "off") {
          light := "on";
        } else {
          light := "off";
        };
        count := count + 1;
      }
  }
}
*)
\* BEGIN TRANSLATION (chksum(pcal) = "6ed0e71" /\ chksum(tla) = "aa7bb02a")
VARIABLES light, count, pc

(* define statement *)
TypeOK == light \in {"on", "off"} /\ count \in 0..3


vars == << light, count, pc >>

ProcSet == {"Person"}

Init == (* Global variables *)
        /\ light = "off"
        /\ count = 0
        /\ pc = [self \in ProcSet |-> "toggle"]

toggle == /\ pc["Person"] = "toggle"
          /\ IF count < 3
                THEN /\ IF light = "off"
                           THEN /\ light' = "on"
                           ELSE /\ light' = "off"
                     /\ count' = count + 1
                     /\ pc' = [pc EXCEPT !["Person"] = "toggle"]
                ELSE /\ pc' = [pc EXCEPT !["Person"] = "Done"]
                     /\ UNCHANGED << light, count >>

switcher == toggle

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == switcher
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(switcher)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
=============================================================================
