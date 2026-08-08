---------------------------- MODULE Lockbox ----------------------------
(***************************************************************************)
(* SUBMISSION: the observation record has the wrong SHAPE.                  *)
(*                                                                          *)
(* This module parses, configures and model-checks perfectly well on its    *)
(* own. What it gets wrong is the graded interface: the reference states    *)
(* its obligations over `o.level`, and this record has no `level` field.    *)
(* So every reference obligation blows up MID-EVALUATION rather than coming *)
(* out false.                                                               *)
(*                                                                          *)
(* That distinction is the whole point of the fixture (bead tla-tkzt, and   *)
(* the four evaluation-failure rows of harness/verdict.sh's table). rc=12   *)
(* means the obligation was checked and is false. rc=75 means the check     *)
(* never happened at all, and the two must not be reported as the same      *)
(* thing.                                                                   *)
(*                                                                          *)
(* Getting the interface wrong is a LEARNER error, so it grades INVALID.    *)
(* It used to reach `die_harness` and exit 4 -- telling the learner nothing *)
(* and telling whoever ran the batch that the harness was broken when it    *)
(* was not.                                                                 *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE colour

Init == colour = "red"

Next == colour' \in {"red", "green"}

Spec == Init /\ [][Next]_colour

(***************************************************************************)
(* `hue`, not `level`. Everything the reference asks about is missing.      *)
(***************************************************************************)
Observe == [hue |-> colour]

=============================================================================
