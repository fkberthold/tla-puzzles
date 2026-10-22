---- MODULE Gantry ----
EXTENDS Integers, FiniteSets
CONSTANT Hands

(***************************************************************************)
(* BellowsSplit written by hand, with no translator anywhere near it.  The  *)
(* five constructs the reference page calls pure TLA+ are all here: `pc`,   *)
(* `ProcSet`, one action per label, `Trans`, and `Terminating`.             *)
(*                                                                         *)
(* It is checked against the same configuration as BellowsSplit, so a       *)
(* reader can compare the two state counts and read the difference as zero. *)
(***************************************************************************)

VARIABLES pc, chamber, seen
vars == << pc, chamber, seen >>

ProcSet == Hands

BothDone == \A h \in Hands : pc[h] = "Done"
NoLoss == BothDone => chamber = Cardinality(Hands)

Init ==
  /\ chamber = 0
  /\ seen = [h \in Hands |-> 0]
  /\ pc = [h \in ProcSet |-> "Stroke"]

Trans(h, from, to) ==
  /\ pc[h] = from
  /\ pc' = [pc EXCEPT ![h] = to]

Stroke(h) ==
  /\ Trans(h, "Stroke", "Push")
  /\ seen' = [seen EXCEPT ![h] = chamber]
  /\ UNCHANGED chamber

Push(h) ==
  /\ Trans(h, "Push", "Done")
  /\ chamber' = seen[h] + 1
  /\ UNCHANGED seen

Terminating == BothDone /\ UNCHANGED vars

Next == (\E h \in Hands : Stroke(h) \/ Push(h)) \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>BothDone
=======================
