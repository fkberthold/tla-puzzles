---- MODULE JigRaw ----
EXTENDS Integers

(***************************************************************************)
(* UNTRANSLATABLE ON PURPOSE, and it has no translated block for that      *)
(* reason.  The `while` below carries no label of its own, which the        *)
(* translator refuses rather than resolving.  Jig.tla is the same source    *)
(* with the one label added.                                                *)
(*                                                                         *)
(* The registered case runs TLC against a module with no behavior formula   *)
(* in it, so the exit code pins the absence of a translated block.  A later *)
(* hand that translates this file will redden the suite, which is what we   *)
(* want: the file's job is to stay untranslated.                            *)
(***************************************************************************)

(*--algorithm jigraw {
  variables bore = 0;
  {
    Start:
      bore := 1;
      while (bore < 3) {
        bore := bore + 1;
      }
  }
}*)
=======================
