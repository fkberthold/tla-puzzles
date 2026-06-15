---- MODULE Oddments ----
(*****************************************************************************)
(* Oddments appendix — these operators do not fit the producer/consumer     *)
(* specimens (Specimen 1/2) coherently, so they are collected here.         *)
(* Deliberately un-idiomatic: a coverage appendix, not a model to imitate.  *)
(*                                                                           *)
(* Each rare operator appears below at least once, on its own line, with a  *)
(* `\* uses: <operator>` marker. The state space is intentionally tiny so   *)
(* TLC terminates instantly. Nothing here models a real system; the only    *)
(* job of this module is to make each oddment operator parse and evaluate.   *)
(*                                                                           *)
(* DOCUMENTED OMISSION — `\cdot` (action composition):                      *)
(*   `\cdot` is in-scope for the pangram set but is NOT TLC-checkable on the *)
(*   standard verify path. TLC refuses action composition unless the JVM is *)
(*   launched with -Dtlc2.tool.impl.Tool.cdot=true (an explicitly           *)
(*   "incomplete implementation"); the verify-puzzle.sh wrapper does not     *)
(*   pass that property, so any live use of `\cdot` in Next/Spec aborts with *)
(*   "The current version of TLC does not support action composition."      *)
(*   It is therefore kept here only as a commented specimen (see the         *)
(*   ActionCompositionDemo block below) and flagged for the operator-card    *)
(*   as a documented omission rather than an executed example.               *)
(*****************************************************************************)
EXTENDS Naturals, Integers, Sequences, TLC, FiniteSets

(* --- Constant oddments: each rare operator exercised once. --- *)

Colors == {"r", "g"}
Sizes  == {1, 2}

Pairs == Colors \X Sizes                  \* uses: \X  (Cartesian product set)

Pow == 2 ^ 3                              \* uses: ^   (exponentiation: 2^3 = 8)

LessThan(a, b) == a < b                    \* comparator for SortSeq (a "<" b)
SortedSeq == SortSeq(<<3, 1, 2>>, LessThan) \* uses: SortSeq  -> <<1, 2, 3>>

PowLabel == "pow=" \o ToString(Pow)        \* uses: ToString (value -> string)

ColorPerms == Permutations(Colors)         \* uses: Permutations (TLC module)

(*****************************************************************************)
(* ActionCompositionDemo — `\cdot` specimen, INTENTIONALLY NOT WIRED IN.     *)
(* Left commented out: TLC aborts on action composition without the          *)
(* -Dtlc2.tool.impl.Tool.cdot=true JVM property, which verify-puzzle.sh does  *)
(* not supply. Shown here purely so the operator's shape is recorded.        *)
(*                                                                           *)
(*   Incr == step' = step + 1                                                *)
(*   Dbl  == step' = step * 2                                                *)
(*   Composed == Incr \cdot Dbl    \* uses: \cdot (action composition)       *)
(*****************************************************************************)

(* --- A genuinely state-dependent spec so the invariant is not constant. ---*)
(* `step` walks 0,1,2 then stutters; the invariant below leans on the        *)
(* oddments above so they are evaluated during model checking.               *)

VARIABLE step

Init == step = 0

Next == step < 2 /\ step' = step + 1

Spec == Init /\ [][Next]_step

(* Invariant references `step` (so it is not constant-level) and asserts the *)
(* oddment results, forcing TLC to evaluate every rare operator above.       *)
OddmentsOK ==
  /\ step \in 0 .. 2
  /\ Cardinality(Pairs) = 4              \* \X produced |Colors| * |Sizes| pairs
  /\ Pow = 8                             \* ^ exponentiation
  /\ SortedSeq = <<1, 2, 3>>            \* SortSeq ascending
  /\ PowLabel = "pow=8"                  \* ToString
  /\ Cardinality(ColorPerms) = 2         \* Permutations of a 2-element set
====
