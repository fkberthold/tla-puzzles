--------------------------- MODULE MCBrokenAction ---------------------------
(***************************************************************************)
(* The same broken system, with the requirement stated the way the brief    *)
(* words it rather than the way Broken.cfg states it.                       *)
(*                                                                         *)
(* "The storage service never accepts a write from a client whose lease has *)
(* expired" is a claim about the INSTANT of the write. No later state       *)
(* carries the fact, so it cannot be a state invariant without adding a     *)
(* history variable. Written honestly it is an action property:             *)
(*                                                                         *)
(*     [][ Write(c) => LeaseLive(c) ]_vars                                  *)
(*                                                                         *)
(* which is the shape `braf' uses seven times in the corpus survey. It is   *)
(* checked with PROPERTY, not INVARIANT, so a failure exits 13 rather than  *)
(* 12. Same defect, different exit code, and that difference is the point   *)
(* of running it separately. See REPORT.md.                                 *)
(***************************************************************************)
EXTENDS Broken

=============================================================================
