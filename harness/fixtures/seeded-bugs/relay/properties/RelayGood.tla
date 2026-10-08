----------------------------- MODULE RelayGood ------------------------------
(***************************************************************************)
(* A TEMPORAL SUBMISSION THAT PASSES THE LIVENESS MATRIX.                   *)
(*                                                                          *)
(* Logically the oracle's `[]<>(stage = 2)`, written as the negation of its *)
(* dual instead: there is no point after which the relay stays away from    *)
(* position 2.  `~<>[]~P` and `[]<>P` are the same formula, so a matrix     *)
(* that only accepted the oracle's own text would be testing string         *)
(* equality.                                                                *)
(*                                                                          *)
(* AND THE OBLIGATION IS REACHED THROUGH A NAME.  `Live` is a bare          *)
(* identifier; the temporal operators are one hop away in                   *)
(* `Reaches2Again`.  That is deliberate.  seeded-bugs.sh decides between    *)
(* `INVARIANT` and `PROPERTY` by the SHAPE of the obligation, and a         *)
(* detector that only looked at the line `Live ==` appears on would classify *)
(* this as a state predicate, write the wrong keyword, and report a verdict  *)
(* about a formula TLC never checked.  Naming the requirement and then       *)
(* checking the name is ordinary practice -- the oracle for the             *)
(* txn-epoch-fence spike does exactly this -- so the row has to be here.     *)
(***************************************************************************)
EXTENDS Relay

Reaches2Again == ~<>[](stage # 2)

Live == Reaches2Again

=============================================================================
