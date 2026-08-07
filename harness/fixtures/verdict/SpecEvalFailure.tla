----------------------- MODULE SpecEvalFailure -----------------------
(***************************************************************************)
(* rc=75 fixture (EC.TLC_STATE_NOT_COMPLETELY_SPECIFIED_NEXT = 2109).       *)
(*                                                                          *)
(* THE ONE ROW IN THIS DIRECTORY THAT WAS NOT INVENTED FOR THE TEST. This   *)
(* is a copy of puzzles/T29-unchanged/solution/Clock_buggy.tla, the v1      *)
(* curriculum's own under-constrained-action demonstration: the non-        *)
(* rollover branch of Tick sets seconds' and forgets minutes', so TLC       *)
(* cannot complete the successor state and dies with                        *)
(*                                                                          *)
(*   Successor state is not completely specified by action Tick of the      *)
(*   next-state relation. The following variable is not defined: minutes.   *)
(*                                                                          *)
(* Copied rather than referenced: puzzles/ is v1 and v2 does not modify it, *)
(* and a fixture that reaches out of harness/fixtures/ would make the       *)
(* verdict table hostage to a curriculum edit.                              *)
(*                                                                          *)
(* This is a SPEC EVALUATION FAILURE, not a property violation. No          *)
(* invariant and no temporal property is checked here at all -- the run     *)
(* never gets far enough to check one. That distinction is why rc=75 has    *)
(* its own token instead of sharing SAFETY_VIOLATION's.                     *)
(*                                                                          *)
(* Do NOT "fix" the missing UNCHANGED. The defect is the fixture.           *)
(***************************************************************************)
EXTENDS Integers

VARIABLES minutes, seconds

TypeOK == minutes \in 0..59 /\ seconds \in 0..59

Init ==
  /\ minutes = 0
  /\ seconds = 0

\* BUG ON PURPOSE: the non-rollover branch forgets to constrain minutes'.
Tick ==
  IF seconds < 59
    THEN seconds' = seconds + 1
    ELSE /\ seconds' = 0
         /\ minutes' = (minutes + 1) % 60

Reset ==
  /\ minutes' = 0
  /\ seconds' = 0

Next == Tick \/ Reset

Spec == Init /\ [][Next]_<<minutes, seconds>>

=============================================================================
